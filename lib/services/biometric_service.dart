import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      // Legacy API usage attempt if named args fail
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access Emote',
        // Omitting options/stickyAuth entirely if they are causing issues
        // Default behavior is usually acceptable for MVP
      );
    } on PlatformException catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }
}
