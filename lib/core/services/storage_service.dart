import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class StorageService {
  final CacheManager _cacheManager = DefaultCacheManager();

  Future<File> cacheFile(String url) async {
    return _cacheManager.getSingleFile(url);
  }
}
