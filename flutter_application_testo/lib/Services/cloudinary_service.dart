import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final cloudinary = CloudinaryPublic('dn7z05psg', 'mobile', cache: false);
  
  // Upload image file to Cloudinary and return the secure URL
  Future<String> uploadImage(File imageFile) async {
    try {
      // Create a CloudinaryFile from the File object
      CloudinaryFile cloudinaryFile = CloudinaryFile.fromFile(
        imageFile.path,
        resourceType: CloudinaryResourceType.Image,
      );
      
      // Upload the image to Cloudinary
      CloudinaryResponse response = await cloudinary.uploadFile(cloudinaryFile);
      
      // Return the secure URL of the uploaded image
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}