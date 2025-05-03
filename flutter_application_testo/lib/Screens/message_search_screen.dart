import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_testo/Models/chat_screen_argments_model.dart';

class MessageSearchScreen extends StatefulWidget {
  const MessageSearchScreen({super.key});

  @override
  State<MessageSearchScreen> createState() => _MessageSearchScreenState();
}

class _MessageSearchScreenState extends State<MessageSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Rechercher des utilisateurs dans Firestore
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final emailSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      setState(() {
        _searchResults = emailSnapshot.docs
            .where((doc) => doc['email'] != FirebaseAuth.instance.currentUser!.email)
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Erreur lors de la recherche: \$e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF00BF6D),
        foregroundColor: Colors.white,
        title: const Text("Recherche"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            color: const Color(0xFF00BF6D),
            child: Form(
              child: TextFormField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _searchUsers(value);
                },
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    Icons.search,
                    color: const Color(0xFF1D1D35).withOpacity(0.64),
                  ),
                  hintText: "Rechercher un utilisateur",
                  hintStyle: TextStyle(
                    color: const Color(0xFF1D1D35).withOpacity(0.64),
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                ),
              ),
            ),
          ),
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                color: const Color(0xFF00BF6D),
              ),
            ),
          Expanded(
            child: _searchQuery.isEmpty
                ? SuggestedContacts(
                    onTap: (user) {
                      final userEmail = user['email'];
                      final username = userEmail.split('@')[0];

                      Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: ChatScreenModel(
                          userId: user['uid'],
                          email: userEmail,
                          userName: username,
                        ),
                      );
                    },
                  )
                : _searchResults.isEmpty && !_isSearching
                    ? const Center(
                        child: Text("Aucun résultat trouvé"),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final doc = _searchResults[index];
                          final String userEmail = doc['email'];
                          final String username = userEmail.split('@')[0];
                          final String displayName = username[0].toUpperCase() + username.substring(1).toLowerCase();
                          final String avatarText = userEmail[0].toUpperCase() + userEmail.split('@')[1][0].toUpperCase();

                          return UserChatCard(
                            press: () {
                              Navigator.pushNamed(
                                context,
                                '/chat',
                                arguments: ChatScreenModel(
                                  userId: doc['uid'],
                                  email: userEmail,
                                  userName: username,
                                ),
                              );
                            },
                            name: displayName,
                            email: userEmail,
                            avatarText: avatarText,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class SuggestedContacts extends StatelessWidget {
  final Function(Map<String, dynamic>) onTap;

  const SuggestedContacts({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Suggestions",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black.withOpacity(0.32),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("Une erreur est survenue"));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF00BF6D),
                ),
              );
            }

            final users = snapshot.data!.docs
                .where((doc) => doc['email'] != FirebaseAuth.instance.currentUser!.email)
                .toList();

            return Column(
              children: users.map((doc) {
                final userData = doc.data() as Map<String, dynamic>;
                final String userEmail = userData['email'];
                final String username = userEmail.split('@')[0];
                final String displayName = username[0].toUpperCase() + username.substring(1).toLowerCase();
                final String avatarText = userEmail[0].toUpperCase() + userEmail.split('@')[1][0].toUpperCase();

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: CircleAvatarWithInitials(text: avatarText),
                  title: Text(
                    displayName,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    userEmail,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black.withOpacity(0.64)),
                  ),
                  onTap: () => onTap(userData),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class UserChatCard extends StatelessWidget {
  const UserChatCard({super.key, required this.press, required this.name, required this.email, required this.avatarText});

  final VoidCallback press;
  final String name;
  final String email;
  final String avatarText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatarWithInitials(text: avatarText),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: 0.64,
                      child: Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
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
        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}