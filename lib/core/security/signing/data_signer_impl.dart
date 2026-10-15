import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';

import '../key_manager_constants.dart';
import '../key_manager_types.dart';
import 'data_signer.dart';

class DataSignerImpl implements DataSigner {
  @override
  Future<Either<KeyManagerFailure, Uint8List>> sign(
    Uint8List data, {
    String keyAlias = 'mtls_client_key',
  }) async {
    try {
      final Uint8List? signature =
          await keyManagerChannel.invokeMethod<Uint8List>(
        'signData',
        {
          'alias': keyAlias,
          'data': data,
        },
      );

      if (signature == null || signature.isEmpty) {
        return const Left(
          KeyManagerFailure.keyStoreError(
            'Native layer returned an empty signature.',
          ),
        );
      }

      return Right(signature);
    } on PlatformException catch (e) {
      if (e.code == 'KEY_INVALIDATED') {
        // Self-healing: remove the orphaned public key from secure storage
        // since the hardware private key was destroyed due to biometric changes.
        await secureStorage.delete(key: publicKeyStorageKey);
        return Left(
          KeyManagerFailure.keyInvalidated(
            e.message ?? 'Key was invalidated due to biometric enrollment changes.',
          ),
        );
      }

      if (e.code == 'AUTH_REQUIRED') {
        return Left(
          KeyManagerFailure.authFailed(
            e.message ?? 'Biometric authentication is required before signing.',
          ),
        );
      }

      if (e.code == 'KEY_NOT_FOUND') {
        return Left(
          KeyManagerFailure.keyStoreError(
            e.message ?? 'No private key found in hardware for alias: $keyAlias',
          ),
        );
      }

      return Left(
        KeyManagerFailure.keyStoreError(
          'Signing failed: ${e.message}',
        ),
      );
    } catch (e) {
      return Left(KeyManagerFailure.unknown(e.toString()));
    }
  }
}