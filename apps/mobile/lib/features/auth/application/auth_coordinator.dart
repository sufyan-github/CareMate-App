import 'package:caremate/features/auth/domain/auth_gateway.dart';
import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/auth/domain/refresh_session_lock.dart';
import 'package:caremate/features/auth/domain/session_store.dart';
import 'package:caremate/features/auth/data/device_locale.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus { restoring, signedOut, awaitingOtp, signedIn }

class AuthCoordinator extends ChangeNotifier {
  AuthCoordinator({
    required this.gateway,
    this.refreshLock = const NoopRefreshSessionLock(),
    required this.sessionStore,
  });

  final AuthGateway gateway;
  final RefreshSessionLock refreshLock;
  final SessionStore sessionStore;

  AuthStatus status = AuthStatus.restoring;
  AuthChallenge? challenge;
  AuthSession? session;
  String? errorMessage;
  bool isBusy = false;

  Future<void> initialize() async {
    final refreshToken = await sessionStore.readRefreshToken();
    if (refreshToken == null) {
      status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    final cachedSession = await sessionStore.readSession();
    try {
      session = await _refreshSession();
      status = AuthStatus.signedIn;
    } on AuthFailure catch (failure) {
      if (failure.code == 'NETWORK_UNAVAILABLE' && cachedSession != null) {
        session = cachedSession;
        errorMessage =
            'CareMate is offline. Showing the secure plan saved on this phone.';
        status = AuthStatus.signedIn;
      } else {
        await sessionStore.clear();
        status = AuthStatus.signedOut;
      }
    }
    notifyListeners();
  }

  Future<bool> requestOtp(String phoneNumber) async {
    return _run(() async {
      challenge = await gateway.requestOtp(
        deviceInstallationId: await sessionStore.installationId(),
        locale: careMateDeviceLocale(),
        phoneNumber: phoneNumber,
      );
      status = AuthStatus.awaitingOtp;
    });
  }

  Future<bool> verifyOtp(String otp) async {
    final activeChallenge = challenge;
    if (activeChallenge == null) return false;
    return _run(() async {
      session = await gateway.verifyOtp(
        challengeId: activeChallenge.challengeId,
        device: AuthDevice(
          appVersion: '1.0.0',
          deviceName: 'Android phone',
          installationId: await sessionStore.installationId(),
        ),
        otp: otp,
      );
      await sessionStore.writeSession(session!);
      status = AuthStatus.signedIn;
    });
  }

  void changePhoneNumber() {
    challenge = null;
    errorMessage = null;
    status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<String> refreshAccessToken() async {
    session = await _refreshSession();
    notifyListeners();
    return session!.accessToken;
  }

  Future<AuthSession> _refreshSession() => refreshLock.synchronized(() async {
    final refreshToken = await sessionStore.readRefreshToken();
    if (refreshToken == null) {
      throw const AuthFailure(
        'SESSION_REVOKED',
        'Your session has ended. Sign in again.',
      );
    }
    final refreshed = await gateway.refresh(refreshToken);
    await sessionStore.writeSession(refreshed);
    return refreshed;
  });

  Future<void> logout() async {
    final accessToken = session?.accessToken;
    if (accessToken != null) {
      await gateway.logout(accessToken);
    }
    await sessionStore.clear();
    challenge = null;
    session = null;
    errorMessage = null;
    status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() operation) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await operation();
      return true;
    } on AuthFailure catch (failure) {
      errorMessage = failure.message;
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}
