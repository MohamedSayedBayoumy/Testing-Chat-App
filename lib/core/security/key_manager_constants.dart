import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const MethodChannel keyManagerChannel = MethodChannel(
  'com.cte.chat/key_manager',
);

const String publicKeyStorageKey = 'mtls_public_key_pem';

const FlutterSecureStorage secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);
