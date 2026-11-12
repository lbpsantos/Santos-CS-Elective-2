import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

// Uploads book covers to the Supabase Storage bucket "product-images"
// (made by supabase/final_project.sql). Only admins may upload.
class StorageService {
  StorageService(this._supabase);

  final SupabaseClient _supabase;

  static const String bucket = 'product-images';

  // Uploads the picture and returns its public link, which is saved in
  // products.image_url.
  Future<String> uploadCover(Uint8List bytes, String fileName) async {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    // A new name every time, so an old cover is never overwritten.
    final path = 'covers/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _supabase.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _contentType(extension)),
        );
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
