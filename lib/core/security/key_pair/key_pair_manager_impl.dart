import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';

import '../key_manager_constants.dart';
import '../key_manager_types.dart';
import 'key_pair_manager.dart';

class KeyPairManagerImpl implements KeyPairManager {
  @override
  Future<Either<KeyManagerFailure, String>> generateAndStore({
    String keyAlias = 'mtls_client_key',
    bool requireAuth = false,
  }) async {
    try {
      final String? publicKeyPem = await keyManagerChannel.invokeMethod<String>(
        'generateKeyPair',
        {
          'alias': keyAlias,
          'requireAuth': requireAuth,
        },
      );

      if (publicKeyPem == null || publicKeyPem.isEmpty) {
        return const Left(
          KeyManagerFailure.keyStoreError(
            'Native layer returned an empty public key.',
          ),
        );
      }

      await secureStorage.write(key: publicKeyStorageKey, value: publicKeyPem);

      return Right(publicKeyPem);
    } on PlatformException catch (e) {
      return Left(
        KeyManagerFailure.keyStoreError(
          'Key generation failed: ${e.message}',
        ),
      );
    } catch (e) {
      return Left(KeyManagerFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<KeyManagerFailure, bool>> hasValidKeyPair({
    String keyAlias = 'mtls_client_key',
  }) async {
    try {
      // 1. Check if the private key exists and is valid inside hardware (Secure Enclave / Keystore).
      final bool hardwareKeyExists =
          await keyManagerChannel.invokeMethod<bool>(
                'hasKeyPair',
                {'alias': keyAlias},
              ) ??
              false;

      // 2. Check if the public key PEM is stored in FlutterSecureStorage.
      final String? storedPem = await secureStorage.read(
        key: publicKeyStorageKey,
      );
      final bool publicKeyExists = storedPem != null && storedPem.isNotEmpty;

      if (hardwareKeyExists && publicKeyExists) {
        return const Right(true);
      }

      // Self-healing: if one side is missing or corrupted, clean up both to stay in sync.
      await delete(keyAlias: keyAlias);
      return const Right(false);
    } on PlatformException catch (e) {
      return Left(
        KeyManagerFailure.keyStoreError(
          'Failed to verify key pair state: ${e.message}',
        ),
      );
    } catch (e) {
      return Left(KeyManagerFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<KeyManagerFailure, String>> getPublicKey() async {
    try {
      final String? pem = await secureStorage.read(key: publicKeyStorageKey);

      if (pem == null || pem.isEmpty) {
        return const Left(
          KeyManagerFailure.keyStoreError(
            'No public key found. Generate a key pair first.',
          ),
        );
      }

      return Right(pem);
    } catch (e) {
      return Left(KeyManagerFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<KeyManagerFailure, Unit>> delete({
    String keyAlias = 'mtls_client_key',
  }) async {
    try {
      await keyManagerChannel.invokeMethod<void>(
        'deleteKeyPair',
        {'alias': keyAlias},
      );
      await secureStorage.delete(key: publicKeyStorageKey);
      return const Right(unit);
    } on PlatformException catch (e) {
      return Left(
        KeyManagerFailure.keyStoreError(
          'Key deletion failed: ${e.message}',
        ),
      );
    } catch (e) {
      return Left(KeyManagerFailure.unknown(e.toString()));
    }
  }
}