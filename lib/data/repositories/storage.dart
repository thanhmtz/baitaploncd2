import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class FireStorage {
  static const String _cloudName = 'dkmmyda3e';
  static const String _uploadPreset = 'tahnmt';

  Future<String> uploadImageToStorage(String childName, Uint8List file, bool isPost) async {
    final String id = const Uuid().v1();
    
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['public_id'] = '$childName/$id';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file,
        filename: '$id.jpg',
      ));
      
      log('Uploading to Cloudinary: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      log('Response: ${response.statusCode} - ${response.body}');
      
      final responseData = jsonDecode(response.body);
      
      if (responseData['secure_url'] != null) {
        return responseData['secure_url'] as String;
      } else if (responseData['error'] != null) {
        throw Exception('Error: ${responseData['error']['message']}');
      } else {
        throw Exception('Failed: ${responseData.toString()}');
      }
    } catch (e) {
      log('Upload error: $e');
      rethrow;
    }
  }
}