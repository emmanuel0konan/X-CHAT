import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_testo/Models/chat_screen_argments_model.dart';
import 'package:flutter_application_testo/Services/authentification.dart';
import 'package:flutter_application_testo/Services/message_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Pour formater les dates

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MessageService _messageService = MessageService();
  bool _showRecent = true; // Pour gérer les onglets (Recent/Active)
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF00BF6D),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text("X-CHAT"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: () async {
              Authentication.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            color: const Color(0xFF00BF6D),
            child: Row(
              children: [
                FillOutlineButton(
                  press: () {
                    setState(() {
                      _showRecent = true;
                    });
                  },
                  text: "Recent Message",
                  isFilled: _showRecent,
                ),
                const SizedBox(width: 16.0),
                FillOutlineButton(
                  press: () {
                    setState(() {
                      _showRecent = false;
                    });
                  },
                  text: "Active",
                  isFilled: !_showRecent,
                ),
              ],
            ),
          ),
          Expanded(
            child: _showRecent ? _buildConversationsList() : _buildUsersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF00BF6D),
        child: const Icon(
          Icons.person_add_alt_1,
          color: Colors.white,
        ),
      ),
    );
  }

  // Méthode pour afficher la liste des conversations récentes
  Widget _buildConversationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _messageService.getChatrooms(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Une erreur est survenue',
              style: GoogleFonts.poppins(
                fontSize: 18.0,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00BF6D),
            ),
          );
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'Aucune conversation',
              style: GoogleFonts.poppins(
                fontSize: 18.0,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final chatDoc = snapshot.data!.docs[index];
            final Map<String, dynamic> data = chatDoc.data() as Map<String, dynamic>;
            
            // Récupérer les IDs des participants
            final List<String> participants = List<String>.from(data['participants']);
            
            // Trouver l'ID de l'autre utilisateur (pas celui connecté actuellement)
            final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
            final String otherUserId = participants.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );
            
            if (otherUserId.isEmpty) {
              return const SizedBox(); // Skip this conversation if no other user found
            }
            
            // On utilise un FutureBuilder pour récupérer les informations de l'utilisateur
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00BF6D)));
                }
                
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SizedBox(); // Skip if user data not found
                }
                
                // Récupérer les données de l'utilisateur
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                final String otherUserEmail = userData?['email'] ?? 'Utilisateur inconnu';
                
                // Formatage du nom d'utilisateur
                final String username = otherUserEmail.split('@')[0];
                final String displayName = username[0].toUpperCase() + 
                            username.substring(1).toLowerCase();
                
                // Initiales pour l'avatar
                final String avatarText = otherUserEmail[0].toUpperCase() + 
                            (otherUserEmail.split('@')[1].isNotEmpty ? 
                            otherUserEmail.split('@')[1][0].toUpperCase() : '');
                
                // Récupérer le dernier message
                final String lastMessage = data['lastMessage'] ?? '';
                
                // Formater la date du dernier message
                String formattedTime = '';
                if (data['lastMessageTime'] != null) {
                  final Timestamp timestamp = data['lastMessageTime'] as Timestamp;
                  final DateTime dateTime = timestamp.toDate();
                  final DateTime now = DateTime.now();
                  
                  if (dateTime.day == now.day && 
                      dateTime.month == now.month && 
                      dateTime.year == now.year) {
                    // Aujourd'hui, on affiche juste l'heure
                    formattedTime = DateFormat('HH:mm').format(dateTime);
                  } else {
                    // Autre jour, on affiche la date
                    formattedTime = DateFormat('dd/MM/yyyy').format(dateTime);
                  }
                }

                return ConversationCard(
                  press: () => Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: ChatScreenModel(
                      userId: otherUserId,
                      email: otherUserEmail,
                      userName: username,
                    ),
                  ),
                  name: displayName,
                  email: otherUserEmail,
                  avatarText: avatarText,
                  lastMessage: lastMessage,
                  time: formattedTime,
                );
              },
            );
          },
        );
      },
    );
  }

  // Méthode pour afficher la liste des utilisateurs (tab Active)
  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Une erreur est survenue',
              style: GoogleFonts.poppins(
                fontSize: 18.0,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF00BF6D),
            ),
          );
        }
        
        return ListView(
          children: snapshot.data!.docs
              .where((doc) =>
                  doc['email'] != FirebaseAuth.instance.currentUser!.email)
              .map<Widget>((doc) {
                final String userEmail = doc['email'];
                final String username = userEmail.split('@')[0];
                final String displayName = username[0].toUpperCase() + 
                            username.substring(1).toLowerCase();
                final String avatarText = userEmail[0].toUpperCase() + 
                            userEmail.split('@')[1][0].toUpperCase();
                    
                return UserChatCard(
                  press: () => Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: ChatScreenModel(
                      userId: doc['uid'],
                      email: userEmail,
                      userName: username,
                    ),
                  ),
                  name: displayName,
                  email: userEmail,
                  avatarText: avatarText,
                );
              }).toList(),
        );
      },
    );
  }
}

class ConversationCard extends StatelessWidget {
  const ConversationCard({
    super.key,
    required this.press,
    required this.name,
    required this.email,
    required this.avatarText,
    required this.lastMessage,
    required this.time,
  });

  final VoidCallback press;
  final String name;
  final String email;
  final String avatarText;
  final String lastMessage;
  final String time;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0 * 0.75),
        child: Row(
          children: [
            CircleAvatarWithInitials(
              text: avatarText,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          time,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        // Ici on pourrait ajouter un indicateur de message non lu si nécessaire
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserChatCard extends StatelessWidget {
  const UserChatCard({
    super.key,
    required this.press,
    required this.name,
    required this.email,
    required this.avatarText,
  });

  final VoidCallback press;
  final String name;
  final String email;
  final String avatarText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0 * 0.75),
        child: Row(
          children: [
            CircleAvatarWithInitials(
              text: avatarText,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: 0.64,
                      child: Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FillOutlineButton extends StatelessWidget {
  const FillOutlineButton({
    super.key,
    this.isFilled = true,
    required this.press,
    required this.text,
  });

  final bool isFilled;
  final VoidCallback press;
  final String text;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: const BorderSide(color: Colors.white),
      ),
      elevation: isFilled ? 2 : 0,
      color: isFilled ? Colors.white : Colors.transparent,
      onPressed: press,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: isFilled ? const Color(0xFF1D1D35) : Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
}

class CircleAvatarWithInitials extends StatelessWidget {
  const CircleAvatarWithInitials({
    super.key,
    required this.text,
    this.radius = 24,
  });

  final String text;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF00BF6D),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}