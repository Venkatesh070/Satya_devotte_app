// lib/core/services/media_upload_service.dart
//
// This service ONLY picks files — it does NOT upload separately.
// The picked file bytes are sent directly in the create/update API calls.
// e.g. POST /poojas/create-pooja (multipart) includes image/audio/video bytes.

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

enum PickMediaType { image, audio, video }

class PickedFile {
  const PickedFile({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });
  final List<int> bytes;
  final String filename;
  final String mimeType;
}

class MediaUploadService extends GetxService {
  /// Pick a file and return its bytes + metadata.
  /// Returns null if user cancelled.
  Future<PickedFile?> pickFile({required PickMediaType type}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: _fileType(type),
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) return null;

      return PickedFile(
        bytes: bytes,
        filename: file.name,
        mimeType: _mimeType(file.name, type),
      );
    } catch (_) {
      return null;
    }
  }

  FileType _fileType(PickMediaType t) {
    switch (t) {
      case PickMediaType.image:
        return FileType.image;
      case PickMediaType.audio:
        return FileType.audio;
      case PickMediaType.video:
        return FileType.video;
    }
  }

  String _mimeType(String filename, PickMediaType t) {
    final ext = filename.split('.').last.toLowerCase();
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
      'mp3': 'audio/mpeg',
      'aac': 'audio/aac',
      'm4a': 'audio/mp4',
      'wav': 'audio/wav',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
    };
    return map[ext] ??
        (t == PickMediaType.image
            ? 'image/jpeg'
            : t == PickMediaType.audio
            ? 'audio/mpeg'
            : 'video/mp4');
  }
}
