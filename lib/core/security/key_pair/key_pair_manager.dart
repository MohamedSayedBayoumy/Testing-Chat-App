import 'package:dartz/dartz.dart';

import '../key_manager_types.dart';

abstract class KeyPairManager {
  Future<Either<KeyManagerFailure, String>> generateAndStore({
    String keyAlias = 'mtls_client_key',
    bool requireAuth = false,
  });

  Future<Either<KeyManagerFailure, bool>> hasValidKeyPair({
    String keyAlias = 'mtls_client_key',
  });

  Future<Either<KeyManagerFailure, String>> getPublicKey();

  Future<Either<KeyManagerFailure, Unit>> delete({
    String keyAlias = 'mtls_client_key',
  });
}