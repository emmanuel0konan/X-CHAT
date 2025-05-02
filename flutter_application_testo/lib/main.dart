import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_testo/Models/chat_screen_argments_model.dart';
import 'package:flutter_application_testo/Screens/chat_screen.dart';
import 'package:flutter_application_testo/Screens/home_screen.dart';
import 'package:flutter_application_testo/Screens/log_screen.dart';
import 'package:flutter_application_testo/Screens/login_screen.dart';
import 'package:flutter_application_testo/Screens/main_screen.dart';
import 'package:flutter_application_testo/Screens/message_details_screen.dart';
import 'package:flutter_application_testo/Screens/message_search_screen.dart';
import 'package:flutter_application_testo/Screens/signup_screen.dart';
import 'package:flutter_application_testo/Screens/splascreen.dart';
import 'package:flutter_application_testo/Services/authentification.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialiser OneSignal ici avant de lancer l'application
  await _initializeOneSignal();
  
  runApp(const MyApp());
}

// Fonction d'initialisation de OneSignal extraite
Future<void> _initializeOneSignal() async {
  // Définir le niveau de log pour le débogage
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  
  // Initialiser OneSignal avec votre App ID
  OneSignal.initialize("7b496c2a-6c26-4294-b25a-d4a9b54c3d49");
  
  // Demander la permission pour les notifications
  OneSignal.Notifications.requestPermission(true);
  
  // Configurer les écouteurs de notifications pour la navigation globale
  _setupGlobalNotificationListeners();
  
  // Stocker le player ID dans Firestore lorsqu'il est disponible
  _savePlayerIdToFirestore();
}

void _setupGlobalNotificationListeners() {
  // Écouteur pour quand l'utilisateur clique sur une notification
  OneSignal.Notifications.addClickListener((event) {
    print('Notification cliquée: ${event.notification.jsonRepresentation()}');
    
    // Vérifier si la notification concerne un message
    if (event.notification.additionalData != null &&
        event.notification.additionalData!.containsKey('senderId')) {
      final senderId = event.notification.additionalData!['senderId'];
      final senderName = event.notification.additionalData!['senderName'];
      final senderEmail = event.notification.additionalData!['senderEmail'];
      
      // La navigation sera gérée dans le MaterialApp via un NavigatorKey
      // ou via un service de navigation global que vous pourrez implémenter
      // Ici, nous stockons simplement l'info pour être utilisée après l'initialisation
      notificationNavData = {
        'type': 'chat_message',
        'senderId': senderId,
        'senderName': senderName,
        'senderEmail': senderEmail,
      };
    }
  });
}

void _savePlayerIdToFirestore() async {
  
  final firebaseAuth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  
  // Observer les changements d'état de la souscription
  OneSignal.User.pushSubscription.addObserver((state) async {
    final userId = firebaseAuth.currentUser?.uid;
    final pushId = state.current.id; // Le player ID de OneSignal
    
    if (userId != null && pushId != null) {
      try {
        // Mettre à jour le document de l'utilisateur avec son player ID OneSignal
        await firestore.collection('users').doc(userId).update({
          'oneSignalId': pushId,
          'oneSignalToken': state.current.token,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('OneSignal ID sauvegardé dans Firestore: $pushId');
      } catch (e) {
        print('Erreur lors de la sauvegarde du OneSignal ID: $e');
      }
    }
  });
}

// Variable globale pour stocker les données de navigation par notification
// à utiliser quand l'app est initialisée
Map<String, dynamic>? notificationNavData;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Clé pour accéder au navigateur depuis n'importe où
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    
    // Vérifier si nous avons des données de navigation par notification
    // et naviguer si nécessaire après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialNotification();
    });
  }
  
  void _handleInitialNotification() {
    if (notificationNavData != null && 
        notificationNavData!['type'] == 'chat_message' &&
        navigatorKey.currentState != null) {
      
      // Naviguer vers le chat avec cet utilisateur
      navigatorKey.currentState!.pushNamed(
        '/chat',
        arguments: ChatScreenModel(
          userId: notificationNavData!['senderId'],
          email: notificationNavData!['senderEmail'],
          userName: notificationNavData!['senderName'],
        ),
      );
      
      // Réinitialiser les données
      notificationNavData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Permet la navigation depuis n'importe où
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final args = settings.arguments as ChatScreenModel;
          return MaterialPageRoute(
            builder: (context) {
              return ChatScreen(
                receiverEmail: args.email,
                receiverUserId: args.userId,
                receiveruserName: args.userName,
              );
            },
          );
        }
        return null;
      },
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => const MainScreen(),
      },
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ).copyWith(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.white,
          onSecondary: Colors.black,
          primaryContainer: Colors.blue,
          onPrimaryContainer: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
    );
  }
}