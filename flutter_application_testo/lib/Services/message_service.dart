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
    
    // Create a chatroom ID by sorting and joining user IDs
    List<String> participantIds = [currentUserId, email];
    participantIds.sort();
    String chatroomId = participantIds.join("*");
    
    // Create or update the chatroom document
    await _fireStore
        .collection('chatrooms')
        .doc(chatroomId)
        .set({
          'lastMessage': message,
          'lastMessageTime': timestamp,
          'participants': participantIds,
          'participantsEmails': [currentUserEmail, email], // Store emails for easier querying
        }, SetOptions(merge: true));
    
    // Add the message to the messages subcollection of the chatroom
    await _fireStore
        .collection('chatrooms')
        .doc(chatroomId)
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
    
    // Create a chatroom ID by sorting and joining user IDs
    List<String> participantIds = [currentUserId, email];
    participantIds.sort();
    String chatroomId = participantIds.join("*");
    
    try {
      String fileUrl = '';
      String fileName = '';
      Map<String, dynamic> messageData = {
        'message': '',
        'receiverId': email,
        'timestamp': timestamp,
        'senderId': currentUserId,
        'senderEmail': currentUserEmail,
        'messageType': fileType,
      };

      // Upload file to Cloudinary based on its type
      if (fileType == 'image' || fileType == 'video' || fileType == 'audio' || fileType == 'document') {
        fileUrl = await _cloudinaryService.uploadImage(file);
        messageData['fileUrl'] = fileUrl;
        
        // Get file name for documents
        if (fileType == 'document') {
          fileName = file.path.split('/').last;
          messageData['fileName'] = fileName;
        }
      }

      // Create or update the chatroom document with last message info
      await _fireStore
          .collection('chatrooms')
          .doc(chatroomId)
          .set({
            'lastMessage': fileType == 'text' ? messageData['message'] : '$fileType sent',
            'lastMessageTime': timestamp,
            'participants': participantIds,
            'participantsEmails': [currentUserEmail, email],
          }, SetOptions(merge: true));
      
      // Add the message to the messages subcollection
      await _fireStore
          .collection('chatrooms')
          .doc(chatroomId)
          .collection('messages')
          .add(messageData);
          
    } catch (e) {
      throw Exception('Failed to send file message: $e');
    }
  }

  // Get messages for a specific chat
  Stream<QuerySnapshot> getMessages({
    required String currentUserId,
    required String receiverUserId,
  }) {
    List<String> chatId = [currentUserId, receiverUserId];
    chatId.sort();
    String chatroomId = chatId.join("*");
    
    return _fireStore
        .collection('chatrooms')
        .doc(chatroomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
  
  // Get all chatrooms for the current user
  Stream<QuerySnapshot> getChatrooms() {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    
    return _fireStore
        .collection('chatrooms')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}