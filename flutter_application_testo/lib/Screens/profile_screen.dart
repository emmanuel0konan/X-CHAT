import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_testo/Services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploading = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current Firebase user
      _currentUser = _auth.currentUser;
      
      if (_currentUser != null) {
        // Fetch additional user data from Firestore
        final docSnapshot = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
            
        if (docSnapshot.exists) {
          setState(() {
            _userData = docSnapshot.data();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _isUploading = true;
      });
      
      try {
        final File imageFile = File(pickedFile.path);
        final String imageUrl = await _cloudinaryService.uploadImage(imageFile);
        
        // Update photo URL in Firestore
        await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .update({'photoUrl': imageUrl});
            
        // Update local data
        setState(() {
          _userData = {...?_userData, 'photoUrl': imageUrl};
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour avec succès!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléchargement: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
  
  void _navigateToEditProfile() {
    // Navigate to edit profile screen
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentUser: _currentUser!,
          userData: _userData,
          onProfileUpdated: _loadUserData,
        ),
      ),
    );
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
        title: const Text("Profil"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text("Veuillez vous connecter"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      ProfilePic(
                        image: _userData?['photoUrl'] ?? 
                            _currentUser?.photoURL ?? 
                            'https://i.postimg.cc/cCsYDjvj/user-2.png',
                        isShowPhotoUpload: true,
                        isUploading: _isUploading,
                        imageUploadBtnPress: _uploadProfileImage,
                      ),
                      Text(
                        _userData?['email'] ?? _currentUser!.displayName ?? 'Utilisateur',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(height: 16.0 * 2),
                      Info(
                        infoKey: "User ID",
                        info: "@${_userData?['username'] ?? _currentUser!.uid.substring(0, 8)}",
                      ),
                      Info(
                        infoKey: "Location",
                        info: _userData?['location'] ?? "Non spécifié",
                      ),
                      Info(
                        infoKey: "Phone",
                        info: _userData?['phone'] ?? _currentUser!.phoneNumber ?? "Non spécifié",
                      ),
                      Info(
                        infoKey: "Email Address",
                        info: _currentUser!.email ?? "Non spécifié",
                      ),
                      const SizedBox(height: 16.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 160,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BF6D),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: _navigateToEditProfile,
                            child: const Text("Modifier profil"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class ProfilePic extends StatelessWidget {
  const ProfilePic({
    super.key,
    required this.image,
    this.isShowPhotoUpload = false,
    this.isUploading = false,
    this.imageUploadBtnPress,
  });

  final String image;
  final bool isShowPhotoUpload;
  final bool isUploading;
  final VoidCallback? imageUploadBtnPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.08),
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(image),
            child: image.isEmpty ? const Icon(Icons.person, size: 50) : null,
          ),
          if (isShowPhotoUpload)
            InkWell(
              onTap: isUploading ? null : imageUploadBtnPress,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: Theme.of(context).primaryColor,
                child: isUploading
                    ? const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            )
        ],
      ),
    );
  }
}

class Info extends StatelessWidget {
  const Info({
    super.key,
    required this.infoKey,
    required this.info,
  });

  final String infoKey, info;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            infoKey,
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .color!
                  .withOpacity(0.8),
            ),
          ),
          Text(info),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final User currentUser;
  final Map<String, dynamic>? userData;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    super.key, 
    required this.currentUser,
    this.userData,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  late TextEditingController _usernameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(
        text: widget.userData?['displayName'] ?? 
             widget.currentUser.displayName ?? '');
             
    _locationController = TextEditingController(
        text: widget.userData?['location'] ?? '');
        
    _phoneController = TextEditingController(
        text: widget.userData?['phone'] ?? 
             widget.currentUser.phoneNumber ?? '');
             
    _usernameController = TextEditingController(
        text: widget.userData?['username'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final updatedData = {
          'displayName': _nameController.text,
          'location': _locationController.text,
          'phone': _phoneController.text,
          'username': _usernameController.text,
        };
        
        // Update data in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.uid)
            .update(updatedData);
            
        // Call the callback to refresh parent screen
        widget.onProfileUpdated();
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil mis à jour avec succès!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier profil'),
        backgroundColor: const Color(0xFF00BF6D),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nom d\'utilisateur',
                border: OutlineInputBorder(),
                prefixText: '@',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom d\'utilisateur';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Localisation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BF6D),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: const StadiumBorder(),
              ),
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}