import 'dart:typed_data';

import 'package:my_first_flutter_ui/services/storage_service.dart';

// A StorageService without Supabase: "uploads" return a made-up link.
class FakeStorageService implements StorageService {
  final List<String> uploaded = [];

  @override
  Future<String> uploadCover(Uint8List bytes, String fileName) async {
    uploaded.add(fileName);
    return 'https://example.supabase.co/storage/v1/object/public/'
        'product-images/covers/$fileName';
  }
}
