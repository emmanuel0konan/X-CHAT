import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConversationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenir toutes les conversations pour l'utilisateur actuel
  Stream<QuerySnapshot> getConversations() {
    final String currentUserId = _auth.currentUser!.uid;
    
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  // Créer ou obtenir une conversation existante entre deux utilisateurs
  Future<String> getOrCreateConversation({
    required String otherUserId,
  }) async {
    final String currentUserId = _auth.currentUser!.uid;
    
    // Chercher si une conversation existe déjà entre ces deux utilisateurs
    final QuerySnapshot existingConversations = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .get();

    // Vérifier parmi les conversations de l'utilisateur actuel si l'autre utilisateur y participe
    for (var doc in existingConversations.docs) {
      List<dynamic> participants = doc['participants'];
      if (participants.contains(otherUserId)) {
        // Conversation trouvée
        return doc.id;
      }
    }

    // Si aucune conversation n'existe, en créer une nouvelle
    DocumentReference newConversation = await _firestore.collection('conversations').add({
      'participants': [currentUserId, otherUserId],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
    });

    return newConversation.id;
  }

  // Mettre à jour les informations de la dernière message d'une conversation
  Future<void> updateLastMessage({
    required String conversationId,
    required String message,
    required String senderId,
    String messageType = 'text',
  }) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': message,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
      'lastMessageType': messageType,
    });
  }

  // Obtenir les informations d'un utilisateur
  Future<DocumentSnapshot> getUserInfo(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }
}