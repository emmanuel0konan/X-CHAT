import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_testo/Models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter_application_testo/Services/cloudinary_service.dart';

class MessageService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Send a text message
  Future<void> sendMessage({
    required String message,
    required String email,
  }) async {
    final Timestamp timestamp = Timestamp.now();
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email!;
    
    List<String> chatId = [currentUserId, email];
    chatId.sort();
    
    await _fireStore
      .collection('chat')
      .doc(chatId.join("*"))
      .collection('messages')
      .add(
        MessageModel(
          message: message,
          receiverId: email,
          timestamp: timestamp,
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          messageType: 'text',
        ).toMap(),
      );
  }

  // Send a file message (image, video, audio, document)
  Future<void> sendFileMessage({
    required String email,
    required File file,
    required String fileType,
  }) async {
    final Timestamp timestamp = Timestamp.now();
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email!;
    
    List<String> chatId = [currentUserId, email];
    chatId.sort();

    try {
      // If it's an image, upload it to Cloudinary
      if (fileType == 'image') {
        // Upload the image to Cloudinary and get the URL
        String fileUrl = await _cloudinaryService.uploadImage(file);
        
        // Store only the URL in Firebase
        await _fireStore
          .collection('chat')
          .doc(chatId.join("*"))
          .collection('messages')
          .add({
            'message': '',
            'receiverId': email,
            'timestamp': timestamp,
            'senderId': currentUserId,
            'senderEmail': currentUserEmail,
            'messageType': fileType,
            'fileUrl': fileUrl,
          });
      }
      // Handle other file types similarly if needed
      else if (fileType == 'video' || fileType == 'audio' || fileType == 'document') {
        // For now, upload to Cloudinary as well (you may want different handling)
        String fileUrl = await _cloudinaryService.uploadImage(file);
        
        // Get file name for documents
        String fileName = '';
        if (fileType == 'document') {
          fileName = file.path.split('/').last;
        }
        
        await _fireStore
          .collection('chat')
          .doc(chatId.join("*"))
          .collection('messages')
          .add({
            'message': '',
            'receiverId': email,
            'timestamp': timestamp,
            'senderId': currentUserId,
            'senderEmail': currentUserEmail,
            'messageType': fileType,
            'fileUrl': fileUrl,
            if (fileName.isNotEmpty) 'fileName': fileName,
          });
      }
    } catch (e) {
      throw Exception('Failed to send file message: $e');
    }
  }

  Stream<QuerySnapshot> getMessages({
    required String currentUserId,
    required String receiverUserId,
  }) {
    List<String> chatId = [currentUserId, receiverUserId];
    chatId.sort();
    
    return _fireStore
      .collection('chat')
      .doc(chatId.join("*"))
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots();
  }
}