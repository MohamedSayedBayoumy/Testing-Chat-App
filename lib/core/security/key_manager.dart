import 'dart:convert';
import 'dart:developer';

import 'package:chat_app/core/flavor/app_config.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';

import 'biometric/biometric_auth_impl.dart';
import 'key_manager_types.dart';
import 'key_pair/key_pair_manager_impl.dart';
import 'signing/data_signer_impl.dart';

export 'package:dartz/dartz.dart' show Either, Left, Right, Unit, unit;
export 'key_manager_types.dart';

abstract final class KeyManager {
  static final _biometricAuth = BiometricAuthImpl();
  static final _keyPairManager = KeyPairManagerImpl();
  static final _dataSigner = DataSignerImpl();

  static Future<Either<KeyManagerFailure, bool>> authenticateWithBiometrics({
    String reason = 'Please authenticate to access your secure keys.',
  }) => _biometricAuth.authenticate(reason: reason);

  static Future<Either<KeyManagerFailure, String>> generateAndStoreKeyPair({
    String keyAlias = 'mtls_client_key',
    bool requireAuth = true,
  }) => _keyPairManager.generateAndStore(
    keyAlias: keyAlias,
    requireAuth: requireAuth,
  );

  static Future<Either<KeyManagerFailure, bool>> hasValidKeyPair({
    String keyAlias = 'mtls_client_key',
  }) => _keyPairManager.hasValidKeyPair(keyAlias: keyAlias);

  static Future<Either<KeyManagerFailure, String>> getPublicKey() =>
      _keyPairManager.getPublicKey();

  static Future<Either<KeyManagerFailure, Uint8List>> signData(
    Uint8List data, {
    String keyAlias = 'mtls_client_key',
  }) => _dataSigner.sign(data, keyAlias: keyAlias);

  static Future<Either<KeyManagerFailure, Unit>> deleteKeyPair({
    String keyAlias = 'mtls_client_key',
  }) => _keyPairManager.delete(keyAlias: keyAlias);

  static Future<void> runSecurityLifecycleTest() async {
    log('--- 1. Checking if hardware key pair exists ---');
    final hasKeyResult = await KeyManager.hasValidKeyPair();
    bool keyExists = hasKeyResult.getOrElse(() => false);
    log('Key Pair Exists & Valid: $keyExists');

    if (!keyExists) {
      log('--- 2. Generating new EC P-256 Key Pair in Hardware ---');
      final genResult = await KeyManager.generateAndStoreKeyPair(
        requireAuth: true,
        // requireAuth: AppConfig.isDevelopment ? false : true,
      );
      genResult.fold(
        (failure) => log(
          'Key Gen Failed Completely -> Type: ${failure.type}, Message: ${failure.message}',
        ),
        (pem) => log('Generated Public Key PEM:\n$pem'),
      );
    } else {
      final pubKeyResult = await KeyManager.getPublicKey();
      pubKeyResult.fold(
        (failure) => log('Read Public Key Failed: $failure'),
        (pem) => log('Existing Public Key PEM:\n$pem'),
      );
    }

    log('--- 3. Authenticating with Biometrics ---');
    final authResult = await KeyManager.authenticateWithBiometrics();

    await authResult.fold(
      (failure) async =>
          log('Biometric Auth Failed: ${failure.message} || ${failure.type}'),
      (authenticated) async {
        log('Biometric Auth Success: $authenticated');

        log('--- 4. Signing Transaction Payload with Hardware Private Key ---');
        final payloadBytes = Uint8List.fromList(
          utf8.encode(
            '{"amount": 1000000, "currency": "EGP", "to": "VodafoneCash"}',
          ),
        );

        final signResult = await KeyManager.signData(payloadBytes);
        signResult.fold((failure) => log('Signing Failed: $failure'), (
          signatureBytes,
        ) {
          final signatureBase64 = base64Encode(signatureBytes);
          log('Hardware Signature (Base64): $signatureBase64');
        });
      },
    );
  }
}
