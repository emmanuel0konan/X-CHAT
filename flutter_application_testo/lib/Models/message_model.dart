import 'package:cloud_firestore/cloud_firestore.dart';
class MessageModel {
final String message;
final String senderId;
final String senderEmail;
final String receiverId;
final Timestamp timestamp;
final String messageType;
final String? fileUrl;
final String? fileName;
MessageModel({
required this.message,
required this.senderId,
required this.senderEmail,
required this.receiverId,
required this.timestamp,
this.messageType = 'text',
this.fileUrl,
this.fileName,
 });
// Convert to a map
Map<String, dynamic> toMap() {
return {
'message': message,
'senderId': senderId,
'senderEmail': senderEmail,
'receiverId': receiverId,
'timestamp': timestamp,
'messageType': messageType,
if (fileUrl != null) 'fileUrl': fileUrl,
if (fileName != null) 'fileName': fileName,
 };
 }
// Create a MessageModel from a map
factory MessageModel.fromMap(Map<String, dynamic> map) {
return MessageModel(
message: map['message'] ?? '',
senderId: map['senderId'] ?? '',
senderEmail: map['senderEmail'] ?? '',
receiverId: map['receiverId'] ?? '',
timestamp: map['timestamp'] ?? Timestamp.now(),
messageType: map['messageType'] ?? 'text',
fileUrl: map['fileUrl'],
fileName: map['fileName'],
 );
 }
}