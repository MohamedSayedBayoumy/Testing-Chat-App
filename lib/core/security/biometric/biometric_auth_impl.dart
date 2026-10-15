import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

import '../key_manager_types.dart';
import 'biometric_auth.dart';

class BiometricAuthImpl implements BiometricAuth {
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  Future<Either<KeyManagerFailure, bool>> authenticate({
    String reason = 'Please authenticate to access your secure keys.',
    bool biometricOnly = false,
  }) async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        return const Left(
          KeyManagerFailure.notAvailable(
            'No biometric or device credential is available.',
          ),
        );
      }

      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();

      final String hint = _resolveHint(availableBiometrics);

      final bool authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: 'Authentication Required',
            biometricHint: hint,
            cancelButton: 'Cancel',
          ),
          const IOSAuthMessages(cancelButton: 'Cancel'),
        ],
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        return const Right(true);
      }

      // When authenticate() returns false without throwing, the user cancelled or dismissed the prompt.
      return const Left(
        KeyManagerFailure.userCancelled(
          'Authentication was cancelled by the user.',
        ),
      );
    } on PlatformException catch (e) {
      log('Biometric PlatformException: [${e.code}] ${e.message}');

      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled) {
        return Left(
          KeyManagerFailure.notAvailable(
            e.message ?? 'Biometrics not available or not enrolled.',
          ),
        );
      }

      if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        return Left(
          KeyManagerFailure.authFailed(
            e.message ?? 'Authentication locked out due to too many attempts.',
          ),
        );
      }

      if (e.code == auth_error.passcodeNotSet) {
        return const Left(
          KeyManagerFailure.notAvailable(
            'No device passcode / PIN is set.',
          ),
        );
      }

      if (e.code == 'UserCancel' || e.code == 'SystemCancel') {
        return const Left(
          KeyManagerFailure.userCancelled(),
        );
      }

      return Left(
        KeyManagerFailure.unknown(
          e.message ?? 'Unknown platform authentication error.',
        ),
      );
    } catch (e) {
      log('Biometric unexpected error: $e');
      return Left(KeyManagerFailure.unknown(e.toString()));
    }
  }

  String _resolveHint(List<BiometricType> available) {
    if (available.contains(BiometricType.face)) {
      return 'Use Face ID to authenticate';
    }
    if (available.contains(BiometricType.fingerprint)) {
      return 'Use your fingerprint to authenticate';
    }
    if (available.contains(BiometricType.iris)) {
      return 'Use iris recognition to authenticate';
    }
    return 'Use your device PIN or password to authenticate';
  }
}