import 'package:flutter/material.dart';
import 'package:flutter_application_testo/Services/message_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  final String receiverEmail;
  final String receiverUserId;
  final String receiveruserName;

  const ChatScreen({
    super.key,
    required this.receiverEmail,
    required this.receiverUserId,
    required this.receiveruserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _showAttachment = false;
  File? _selectedFile;
  String _selectedFileType = '';

  void _updateAttachmentState() {
    setState(() {
      _showAttachment = !_showAttachment;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _messageService.sendMessage(
        email: widget.receiverUserId,
        message: _messageController.text,
      );
      _messageController.clear();
    }
  }

  Future<void> _sendFileMessage() async {
  if (_selectedFile != null) {
    try {
      // Show loading indicator
      setState(() {
        _isUploading = true;
      });
      
      // Send the file message
      await _messageService.sendFileMessage(
        email: widget.receiverUserId,
        file: _selectedFile!,
        fileType: _selectedFileType,
      );
      
      // Reset state
      setState(() {
        _selectedFile = null;
        _selectedFileType = '';
        _showAttachment = false;
        _isUploading = false;
      });
    } catch (e) {
      // Hide loading indicator
      setState(() {
        _isUploading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi du fichier: $e')),
      );
    }
  }
}


 Future<void> _pickImage(ImageSource source) async {
  try {
    final XFile? selectedImage = await _imagePicker.pickImage(
      source: source,
      imageQuality: 70,
    );
    
    if (selectedImage != null) {
      setState(() {
        _selectedFile = File(selectedImage.path);
        _selectedFileType = 'image';
      });
      
      // Send the file message
      await _sendFileMessage();
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
    );
  }
}
// Add this boolean to your state variables at the top of the class
bool _isUploading = false;
Future<void> _pickVideo() async {
    try {
      final XFile? selectedVideo = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      
      if (selectedVideo != null) {
        setState(() {
          _selectedFile = File(selectedVideo.path);
          _selectedFileType = 'video';
        });
        
        await _sendFileMessage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de la vidéo: $e')),
      );
    }
  }
  
  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      
      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileType = 'document';
        });
        
        await _sendFileMessage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection du document: $e')),
      );
    }
  }

  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      
      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileType = 'audio';
        });
        
        await _sendFileMessage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection du fichier audio: $e')),
      );
    }
  }

  String _formatDate(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (dateToCheck == today) {
      return 'Aujourd\'hui, ${DateFormat.Hm().format(timestamp)}';
    } else if (dateToCheck == yesterday) {
      return 'Hier, ${DateFormat.Hm().format(timestamp)}';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
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
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const BackButton(),
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Text(
                widget.receiveruserName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16.0 * 0.75),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiveruserName[0].toUpperCase() +
                      widget.receiveruserName.substring(1).toLowerCase(),
                  style: const TextStyle(fontSize: 16),
                ),
                const Text(
                  "Active now",
                  style: TextStyle(fontSize: 12),
                )
              ],
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_phone),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
          ),
          const SizedBox(width: 16.0 / 2),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder(
              stream: _messageService.getMessages(
                receiverUserId: widget.receiverUserId,
                currentUserId: _firebaseAuth.currentUser!.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Something went wrong',
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

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                // Regrouper les messages par date
                final messagesData = snapshot.data!.docs;
                Map<String, List<Map<String, dynamic>>> groupedMessages = {};

                for (var doc in messagesData) {
                  final data = doc.data() as Map<String, dynamic>;
                  final DateTime timestamp = (data['timestamp'] as dynamic).toDate();
                  final String dateKey = DateFormat('yyyy-MM-dd').format(timestamp);
                  
                  if (!groupedMessages.containsKey(dateKey)) {
                    groupedMessages[dateKey] = [];
                  }
                  
                  groupedMessages[dateKey]!.add(data);
                }

                // Trier les clés de date par ordre chronologique
                final sortedDates = groupedMessages.keys.toList()
                  ..sort((a, b) => a.compareTo(b));

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: sortedDates.length,
                    itemBuilder: (context, dateIndex) {
                      final date = sortedDates[dateIndex];
                      final messages = groupedMessages[date]!;
                      
                      // Convertir la clé de date en DateTime
                      final DateTime dateTime = DateTime.parse(date);
                      
                      return Column(
                        children: [
                          // Date header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _formatDate(dateTime).split(',')[0], // "Aujourd'hui" ou "Hier" ou la date
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Messages for this date
                          ...messages.map((data) {
                            final bool isSender = data['senderId'] == _firebaseAuth.currentUser!.uid;
                            final DateTime timestamp = (data['timestamp'] as dynamic).toDate();
                            final String messageType = data['messageType'] ?? 'text';
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Column(
                                crossAxisAlignment: isSender
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: isSender
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!isSender) ...[
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.grey[300],
                                          child: Text(
                                            widget.receiveruserName[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16.0 / 2),
                                      ],
                                      
                                      // Message content based on type
                                      if (messageType == 'text')
                                        Container(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0 * 0.75,
                                            vertical: 16.0 / 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00BF6D)
                                                .withOpacity(isSender ? 1 : 0.1),
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: Text(
                                            data['message'],
                                            style: TextStyle(
                                              color: isSender
                                                  ? Colors.white
                                                  : Theme.of(context).textTheme.bodyLarge!.color,
                                            ),
                                          ),
                                        )
                                      else if (messageType == 'image')
                                        Container(
                                          width: MediaQuery.of(context).size.width * 0.45,
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(15),
                                            color: isSender
                                                ? const Color(0xFF00BF6D).withOpacity(0.1)
                                                : Colors.grey[200],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(15),
                                            child: Image.network(
                                              data['fileUrl'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Padding(
                                                  padding: EdgeInsets.all(10.0),
                                                  child: Icon(Icons.broken_image, color: Colors.grey),
                                                );
                                              },
                                            ),
                                          ),
                                        )
                                      else if (messageType == 'video')
                                        Container(
                                          width: MediaQuery.of(context).size.width * 0.45,
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(15),
                                            color: isSender
                                                ? const Color(0xFF00BF6D).withOpacity(0.1)
                                                : Colors.grey[200],
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(15),
                                                child: Image.network(
                                                  data['thumbnailUrl'] ?? 'https://via.placeholder.com/150',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Padding(
                                                      padding: EdgeInsets.all(10.0),
                                                      child: Icon(Icons.broken_image, color: Colors.grey),
                                                    );
                                                  },
                                                ),
                                              ),
                                              Container(
                                                height: 40,
                                                width: 40,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF00BF6D),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.play_arrow,
                                                  size: 24,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (messageType == 'audio')
                                        Container(
                                          width: MediaQuery.of(context).size.width * 0.55,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0 * 0.75,
                                            vertical: 16.0 / 2.5,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(30),
                                            color: const Color(0xFF00BF6D).withOpacity(isSender ? 1 : 0.1),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.play_arrow,
                                                color: isSender ? Colors.white : const Color(0xFF00BF6D),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16.0 / 2),
                                                  child: Stack(
                                                    clipBehavior: Clip.none,
                                                    alignment: Alignment.center,
                                                    children: [
                                                      Container(
                                                        width: double.infinity,
                                                        height: 2,
                                                        color: isSender
                                                            ? Colors.white
                                                            : const Color(0xFF00BF6D).withOpacity(0.4),
                                                      ),
                                                      Positioned(
                                                        left: 0,
                                                        child: Container(
                                                          height: 8,
                                                          width: 8,
                                                          decoration: BoxDecoration(
                                                            color: isSender
                                                                ? Colors.white
                                                                : const Color(0xFF00BF6D),
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                "0:37",
                                                style: TextStyle(
                                                    fontSize: 12, color: isSender ? Colors.white : null),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (messageType == 'document')
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                            vertical: 12.0,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(15),
                                            color: isSender
                                                ? const Color(0xFF00BF6D)
                                                : const Color(0xFF00BF6D).withOpacity(0.1),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.insert_drive_file,
                                                color: isSender ? Colors.white : const Color(0xFF00BF6D),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                data['fileName'] ?? 'Document',
                                                style: TextStyle(
                                                  color: isSender ? Colors.white : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      
                                      if (isSender)
                                        Container(
                                          margin: const EdgeInsets.only(left: 16.0 / 2),
                                          height: 12,
                                          width: 12,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00BF6D),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.done,
                                            size: 8,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                  
                                  // Timestamp
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 4,
                                      left: isSender ? 0 : 24,
                                      right: isSender ? 12 : 0,
                                    ),
                                    child: Text(
                                      DateFormat.Hm().format(timestamp),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0 / 2,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -4),
                  blurRadius: 32,
                  color: const Color(0xFF087949).withOpacity(0.08),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.mic, color: Color(0xFF00BF6D)),
                        onPressed: () {
                          // Implémentation de l'enregistrement audio
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: "Type message",
                            suffixIcon: SizedBox(
                              width: 65,
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: _updateAttachmentState,
                                    child: Icon(
                                      Icons.attach_file,
                                      color: _showAttachment
                                          ? const Color(0xFF00BF6D)
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .color!
                                              .withOpacity(0.64),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0 / 2),
                                    child: InkWell(
                                      onTap: () => _pickImage(ImageSource.camera),
                                      child: Icon(
                                        Icons.camera_alt_outlined,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color!
                                            .withOpacity(0.64),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            filled: true,
                            fillColor:
                                const Color(0xFF00BF6D).withOpacity(0.08),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0 * 1.5, vertical: 16.0),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00BF6D),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showAttachment) 
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAttachmentOption(
                            icon: Icons.insert_drive_file,
                            title: "Document",
                            onTap: _pickDocument,
                          ),
                          _buildAttachmentOption(
                            icon: Icons.image,
                            title: "Gallery",
                            onTap: () => _pickImage(ImageSource.gallery),
                          ),
                          _buildAttachmentOption(
                            icon: Icons.headset,
                            title: "Audio",
                            onTap: _pickAudio,
                          ),
                          _buildAttachmentOption(
                            icon: Icons.videocam,
                            title: "Video",
                            onTap: _pickVideo,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0 / 2),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0 * 0.75),
              decoration: const BoxDecoration(
                color: Color(0xFF00BF6D),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16.0 / 2),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .color!
                        .withOpacity(0.8),
                  ),
            )
          ],
        ),
      ),
    );
  }
}