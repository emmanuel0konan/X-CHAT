import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final cloudinary = CloudinaryPublic('dn7z05psg', 'mobile', cache: false);
  
  Future<String> uploadImage(File imageFile) async {
    try {
      CloudinaryFile cloudinaryFile = CloudinaryFile.fromFile(
        imageFile.path,
        resourceType: CloudinaryResourceType.Image,
      );
      
      CloudinaryResponse response = await cloudinary.uploadFile(cloudinaryFile);
      
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}