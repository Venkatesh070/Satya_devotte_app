// lib/core/services/media_upload_service.dart
//
// This service ONLY picks files — it does NOT upload separately.
// The picked file bytes are sent directly in the create/update API calls.
// e.g. POST /poojas/create-pooja (multipart) includes image/audio/video bytes.

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick one or more image files (e.g. damage photos for replacement requests).
  Future<List<PickedFile>> pickImages({bool allowMultiple = true}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
        withReadStream: true,
        allowMultiple: allowMultiple,
      );
      if (result == null || result.files.isEmpty) return const [];

      final picked = <PickedFile>[];
      for (final file in result.files) {
        final bytes = await _loadPlatformFileBytes(file);
        if (bytes == null || bytes.isEmpty) continue;
        picked.add(
          PickedFile(
            bytes: bytes,
            filename: file.name,
            mimeType: _mimeType(file.name, PickMediaType.image),
          ),
        );
      }
      return picked;
    } catch (e) {
      debugPrint('pickImages error: $e');
      return const [];
    }
  }

  /// Capture image from camera
  Future<PickedFile?> captureImage() async {
    try {
      // Request camera permission first
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        debugPrint('Camera permission not granted');
        return null;
      }

      final XFile? xFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (xFile == null) {
        debugPrint('No image captured from camera');
        return null;
      }

      final bytes = await xFile.readAsBytes();
      if (bytes.isEmpty) {
        debugPrint('Captured image has no bytes');
        return null;
      }

      return PickedFile(
        bytes: bytes,
        filename: xFile.name,
        mimeType: _mimeType(xFile.name, PickMediaType.image),
      );
    } catch (e) {
      debugPrint('captureImage error: $e');
      return null;
    }
  }

  /// Pick a file and return its bytes + metadata.
  /// Returns null if user cancelled.
  Future<PickedFile?> pickFile({required PickMediaType type}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: _fileType(type),
        withData: true,
        withReadStream: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final bytes = await _loadPlatformFileBytes(file);
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

  /// Web often returns [PlatformFile.bytes] as null; read stream or path instead.
  Future<List<int>?> _loadPlatformFileBytes(PlatformFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return file.bytes!;
    }
    final stream = file.readStream;
    if (stream != null) {
      final builder = BytesBuilder(copy: false);
      await stream.forEach(builder.add);
      final data = builder.takeBytes();
      if (data.isNotEmpty) return data;
    }
    return null;
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
