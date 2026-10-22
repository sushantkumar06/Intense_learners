import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

class UploadedFile {
  final String url;
  final String name;
  final String size;
  final String? type;

  UploadedFile({
    required this.url,
    required this.name,
    required this.size,
    this.type,
  });
}

class UploadService {
  final Dio _dio;
  
  UploadService(this._dio);

  Future<UploadedFile?> pickAndUploadPDF() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result.isEmpty) return null;

    final file = result.first;
    if (file.path == null) return null;

    final size = file.lengthSync() ?? 0;
    if (size > 16 * 1024 * 1024) {
      throw Exception("File size must be less than 16MB");
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      ),
    });

    final response = await _dio.post(
      '/api/mobile/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data;
    return UploadedFile(
      url: data['url'] as String,
      name: data['name'] as String,
      size: '${((data['size'] as num) / 1024 / 1024).toStringAsFixed(2)} MB',
    );
  }

  Future<UploadedFile?> pickAndUploadFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result.isEmpty) return null;

    final file = result.first;
    if (file.path == null) return null;

    final size = file.lengthSync() ?? 0;
    if (size > 32 * 1024 * 1024) {
      throw Exception("File size must be less than 32MB");
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      ),
    });

    final response = await _dio.post(
      '/api/mobile/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data;
    final ext = file.extension?.toLowerCase() ?? '';
    final String type = ext == 'pdf' ? 'pdf' : (['jpg', 'jpeg', 'png'].contains(ext) ? 'image' : 'doc');

    return UploadedFile(
      url: data['url'] as String,
      name: data['name'] as String,
      size: '${((data['size'] as num) / 1024 / 1024).toStringAsFixed(2)} MB',
      type: type,
    );
  }

  Future<UploadedFile?> pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return null;

    final file = File(image.path);
    final int size = await file.length();
    
    if (size > 16 * 1024 * 1024) {
      throw Exception("Image size must be less than 16MB");
    }
    
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        image.path,
        filename: image.name,
      ),
    });

    final response = await _dio.post(
      '/api/mobile/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data;
    return UploadedFile(
      url: data['url'] as String,
      name: data['name'] as String,
      size: '${((data['size'] as num) / 1024 / 1024).toStringAsFixed(2)} MB',
    );
  }
}

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(ref.watch(dioProvider));
});
