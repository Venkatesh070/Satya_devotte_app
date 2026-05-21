import 'dart:io' show Platform;

bool get notificationPlatformIsAndroid => Platform.isAndroid;
bool get notificationPlatformIsIOS => Platform.isIOS;
bool get notificationPlatformIsMacOS => Platform.isMacOS;
