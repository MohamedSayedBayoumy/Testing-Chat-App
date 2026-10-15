enum KeyManagerFailureType {
  userCancelled,
  notAvailable,
  authFailed,
  keyInvalidated,
  keyStoreError,
  unknown,
}

class KeyManagerFailure {
  final KeyManagerFailureType type;
  final String? message;

  const KeyManagerFailure({
    required this.type,
    this.message,
  });

  const KeyManagerFailure.userCancelled([
    this.message = 'Authentication cancelled by user',
  ]) : type = KeyManagerFailureType.userCancelled;

  const KeyManagerFailure.notAvailable([
    this.message = 'Biometrics or credentials not available',
  ]) : type = KeyManagerFailureType.notAvailable;

  const KeyManagerFailure.authFailed([
    this.message = 'Authentication failed',
  ]) : type = KeyManagerFailureType.authFailed;

  const KeyManagerFailure.keyInvalidated([
    this.message = 'Security key was invalidated due to biometric changes',
  ]) : type = KeyManagerFailureType.keyInvalidated;

  const KeyManagerFailure.keyStoreError([
    this.message = 'KeyStore operation failed',
  ]) : type = KeyManagerFailureType.keyStoreError;

  const KeyManagerFailure.unknown([
    this.message = 'An unknown error occurred',
  ]) : type = KeyManagerFailureType.unknown;

  @override
  String toString() =>
      'KeyManagerFailure(type: $type${message != null ? ', message: $message' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyManagerFailure &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message;

  @override
  int get hashCode => type.hashCode ^ message.hashCode;
}