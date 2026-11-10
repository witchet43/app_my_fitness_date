import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'auth_session.dart';

/// A non-persistent QA-only session; rotated refresh tokens stay in memory.
/// The lifecycle revision prevents logout/refresh races from restoring a session.
class IdentitySessionManager extends ChangeNotifier {
  IdentitySessionManager(this.api);

  final ApiClient api;
  IdentitySession? _session;
  Future<IdentitySession?>? _refreshing;
  int _revision = 0;

  IdentitySession? get session => _session;
  bool get signedIn => _session != null;

  Future<void> signIn(String email, String password) async {
    final revision = ++_revision;
    final result = await api.signIn(email: email, password: password);
    if (revision != _revision) {
      throw const IdentityException('El inicio de sesión fue cancelado.');
    }
    _session = result;
    notifyListeners();
  }

  Future<IdentitySession?> refreshIfNeeded() async {
    final current = _session;
    if (current == null) return null;
    if (current.expiresAt.isAfter(DateTime.now().toUtc().add(
      const Duration(seconds: 90),
    ))) {
      return current;
    }
    return _refreshing ??= _renew(current, _revision);
  }

  Future<IdentitySession?> _renew(IdentitySession prior, int revision) async {
    try {
      final next = await api.refreshSession(refreshToken: prior.refreshToken);
      if (revision != _revision || !identical(_session, prior)) return null;
      if (next.user.id != prior.user.id) {
        clear();
        throw const IdentityException('La sesión ya no es válida.');
      }
      _session = next; // Refresh token rotation is atomic in memory.
      notifyListeners();
      return next;
    } catch (_) {
      if (revision == _revision && identical(_session, prior)) clear();
      rethrow;
    } finally {
      _refreshing = null;
    }
  }

  Future<void> validateCurrentIdentity() async {
    final current = await refreshIfNeeded();
    if (current == null) return;
    try {
      final identity = await api.identity(accessToken: current.accessToken);
      if (identity.id != current.user.id) {
        clear();
        throw const IdentityException('La sesión ya no es válida.');
      }
    } catch (_) {
      if (identical(_session, current)) clear();
      rethrow;
    }
  }

  /// Clear local tokens first even if the network fails to revoke remotely.
  Future<void> signOut() async {
    final current = _session;
    clear();
    if (current == null) return;
    await api.signOut(accessToken: current.accessToken);
  }

  void clear() {
    _revision++;
    _session = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _revision++;
    _session = null;
    super.dispose();
  }
}
