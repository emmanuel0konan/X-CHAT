import 'dart:convert';
import 'package:http/http.dart' as http;

class OneSignalService {
  // Remplacez par votre clé API REST OneSignal
  static const String oneSignalRestApiKey = 'os_v2_app_pnewyktmezbjjms22su3ktb5jhiptscwto3uzzuekttfj4fx6y3wtf37argv4jxkfg75qihjp6hsenqz46qgphbmlqq7hy4yt7qm3fa';
  // Remplacez par votre APP ID OneSignal
  static const String oneSignalAppId = '7b496c2a-6c26-4294-b25a-d4a9b54c3d49';
  
  // Endpoint pour l'API OneSignal
  static const String apiUrl = 'https://onesignal.com/api/v1/notifications';

  // Méthode pour envoyer une notification à un utilisateur spécifique via OneSignal
  static Future<bool> sendNotification({
    required String playerId,
    required String title,
    required String content,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Préparer l'en-tête de la requête avec la clé API
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $oneSignalRestApiKey',
      };

      // Préparer le corps de la requête
      final body = jsonEncode({
        'app_id': oneSignalAppId,
        'include_player_ids': [playerId],
        'headings': {'en': title},
        'contents': {'en': content},
        'data': additionalData ?? {},
      });

      // Envoyer la requête à l'API OneSignal
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: body,
      );

      // Vérifier la réponse
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Notification envoyée avec succès: ${response.body}');
        return true;
      } else {
        print('Erreur lors de l\'envoi de la notification: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception lors de l\'envoi de la notification: $e');
      return false;
    }
  }

  // Méthode pour envoyer une notification de message de chat
  static Future<bool> sendChatMessageNotification({
    required String receiverPlayerId,
    required String senderName,
    required String senderId,
    required String senderEmail,
    required String messageContent,
  }) async {
    return await sendNotification(
      playerId: receiverPlayerId,
      title: 'Nouveau message',
      content: '$senderName: $messageContent',
      additionalData: {
        'type': 'chat_message',
        'senderId': senderId,
        'senderName': senderName,
        'senderEmail': senderEmail,
      },
    );
  }
}