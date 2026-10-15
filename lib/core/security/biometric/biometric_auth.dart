import 'package:dartz/dartz.dart';

import '../key_manager_types.dart';

abstract class BiometricAuth {
  Future<Either<KeyManagerFailure, bool>> authenticate({
    String reason = 'Please authenticate to access your secure keys.',
  });
}
