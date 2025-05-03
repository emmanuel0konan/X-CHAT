import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_testo/Models/chat_screen_argments_model.dart';
import 'package:flutter_application_testo/Services/authentification.dart';
import 'package:flutter_application_testo/Services/message_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MessageService _messageService = MessageService();
  bool _showRecent = true;

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
                  text: "Messages Recents",
                  isFilled: _showRecent,
                ),
                const SizedBox(width: 16.0),
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
            child: CircularProgressIndicator(color: Color(0xFF00BF6D)),
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
            final data = chatDoc.data() as Map<String, dynamic>;
            final participants = List<String>.from(data['participants']);
            final currentUserId = FirebaseAuth.instance.currentUser!.uid;
            final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');

            if (otherUserId.isEmpty) return const SizedBox();

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) return const SizedBox();

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final email = userData['email'] ?? '';
                final username = email.split('@')[0];
                final displayName = username[0].toUpperCase() + username.substring(1);
                final avatarText = email[0].toUpperCase() + (email.contains('@') ? email.split('@')[1][0].toUpperCase() : '');
                final photoUrl = userData['photoUrl'];
                final lastMessage = data['lastMessage'] ?? '';
                String time = '';
                if (data['lastMessageTime'] != null) {
                  final timestamp = data['lastMessageTime'] as Timestamp;
                  final dateTime = timestamp.toDate();
                  final now = DateTime.now();
                  time = dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year
                      ? DateFormat('HH:mm').format(dateTime)
                      : DateFormat('dd/MM/yyyy').format(dateTime);
                }

                return ConversationCard(
                  press: () => Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: ChatScreenModel(userId: otherUserId, email: email, userName: username),
                  ),
                  name: displayName,
                  email: email,
                  avatarText: avatarText,
                  photoUrl: photoUrl,
                  lastMessage: lastMessage,
                  time: time,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Une erreur est survenue',
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00BF6D)));
        }

        return ListView(
          children: snapshot.data!.docs
              .where((doc) => doc['email'] != FirebaseAuth.instance.currentUser!.email)
              .map<Widget>((doc) {
            final userEmail = doc['email'];
            final username = userEmail.split('@')[0];
            final displayName = username[0].toUpperCase() + username.substring(1);
            final avatarText = userEmail[0].toUpperCase() + userEmail.split('@')[1][0].toUpperCase();
            final photoUrl = doc['photoUrl'];

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
              photoUrl: photoUrl,
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
    this.photoUrl,
  });

  final VoidCallback press;
  final String name;
  final String email;
  final String avatarText;
  final String lastMessage;
  final String time;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            photoUrl != null && photoUrl!.isNotEmpty
                ? CircleAvatar(radius: 24, backgroundImage: NetworkImage(photoUrl!))
                : CircleAvatarWithInitials(text: avatarText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
                      Text(time, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            )
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
    this.photoUrl,
  });

  final VoidCallback press;
  final String name;
  final String email;
  final String avatarText;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            photoUrl != null && photoUrl!.isNotEmpty
                ? CircleAvatar(radius: 24, backgroundImage: NetworkImage(photoUrl!))
                : CircleAvatarWithInitials(text: avatarText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FillOutlineButton extends StatelessWidget {
  const FillOutlineButton({super.key, this.isFilled = true, required this.press, required this.text});

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
  const CircleAvatarWithInitials({super.key, required this.text, this.radius = 24});

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
