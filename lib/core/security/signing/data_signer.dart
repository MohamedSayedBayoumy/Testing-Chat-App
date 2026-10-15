import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';

import '../key_manager_types.dart';

abstract class DataSigner {
  Future<Either<KeyManagerFailure, Uint8List>> sign(
    Uint8List data, {
    String keyAlias = 'mtls_client_key',
  });
}
