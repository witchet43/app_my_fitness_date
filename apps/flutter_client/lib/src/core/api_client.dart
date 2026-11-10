import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_session.dart';

/// Single HTTPS entry point. The Flutter app never queries Supabase directly.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _http = client ?? http.Client(),
        baseUrl = (baseUrl ??
                const String.fromEnvironment('MFD_API_BASE_URL'))
            .trim();

  final http.Client _http;
  final String baseUrl;

  bool get isConfigured => baseUrl.isNotEmpty;

  Uri _uri(String path, [Map<String, String>? query]) {
    if (!isConfigured) {
      throw StateError('API Gateway not configured');
    }
    final parsed = Uri.parse(baseUrl);
    final local = parsed.host == '127.0.0.1' || parsed.host == 'localhost';
    if (!(parsed.scheme == 'https' || (local && parsed.scheme == 'http')) ||
        parsed.userInfo.isNotEmpty ||
        parsed.hasQuery ||
        parsed.hasFragment) {
      throw StateError('Invalid API Gateway URL');
    }
    return parsed.replace(path: path, queryParameters: query);
  }

  Future<bool> health() async {
    final response = await _http.get(_uri('/healthz')).timeout(
      const Duration(seconds: 8),
    );
    if (response.statusCode != 200) return false;
    final result = jsonDecode(response.body);
    return result is Map && result['status'] == 'ok';
  }

  /// Readiness verifies the real PostgreSQL dependency, unlike liveness.
  /// A healthy process can still be unable to serve user requests.
  Future<bool> readiness() async {
    final response = await _http.get(_uri('/readyz')).timeout(
      const Duration(seconds: 8),
    );
    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body);
    if (data is! Map || data['status'] != 'ok') return false;
    final dependencies = data['dependencies'];
    return dependencies is Map && dependencies['database'] == 'ok' &&
        data['checked_at'] is String &&
        (data['checked_at'] as String).isNotEmpty;
  }

  // QA Auth is proxied exclusively via the API Gateway. Public signup is absent.
  // Refresh tokens are held in memory by IdentitySessionManager, not disk.
  Future<IdentitySession> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const IdentityException('Ingresa correo y contraseña.');
    }
    final data = await _identityRequest(
      () => _http.post(
        _uri('/v1/identity/session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ),
    );
    return _parseSession(data);
  }

  Future<IdentitySession> refreshSession({required String refreshToken}) async {
    if (refreshToken.isEmpty) {
      throw const IdentityException('Sesión no disponible.');
    }
    final data = await _identityRequest(
      () => _http.post(
        _uri('/v1/identity/session/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ),
    );
    return _parseSession(data);
  }

  Future<IdentityUser> identity({required String accessToken}) async {
    if (accessToken.isEmpty) {
      throw const IdentityException('Sesión no disponible.');
    }
    final data = await _identityRequest(
      () => _http.get(
        _uri('/v1/identity/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    try {
      return IdentityUser.fromJson(data);
    } catch (_) {
      throw const IdentityException('Sesión no disponible.');
    }
  }

  Future<void> signOut({required String accessToken}) async {
    if (accessToken.isEmpty) return;
    try {
      final response = await _http.delete(
        _uri('/v1/identity/session'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode != 204) {
        throw const IdentityException(
          'No fue posible confirmar el cierre remoto de sesión.',
        );
      }
    } on IdentityException {
      rethrow;
    } catch (_) {
      throw const IdentityException(
        'No fue posible confirmar el cierre remoto de sesión.',
      );
    }
  }

  IdentitySession _parseSession(Map<String, dynamic> data) {
    try {
      return IdentitySession.fromJson(data);
    } catch (_) {
      throw const IdentityException('Respuesta de identidad inválida.');
    }
  }

  Future<Map<String, dynamic>> _identityRequest(
    Future<http.Response> Function() send,
  ) async {
    try {
      final response = await send().timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          throw const IdentityException('El acceso QA no está habilitado.');
        }
        if (response.statusCode == 429) {
          throw const IdentityException('Demasiados intentos. Intenta más tarde.');
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw const IdentityException('No se pudo verificar la identidad.');
        }
        throw const IdentityException('Servicio de identidad no disponible.');
      }
      final value = jsonDecode(response.body);
      if (value is! Map) {
        throw const IdentityException('Respuesta de identidad inválida.');
      }
      return Map<String, dynamic>.from(value);
    } on IdentityException {
      rethrow;
    } catch (_) {
      // No exception detail, URL, provider payload, email, password or JWT.
      throw const IdentityException('Servicio de identidad no disponible.');
    }
  }

  /// Requires a validated access token from IdentitySessionManager.
  /// No secret, Supabase URL, gym, or training schedule lives in this client.
  Future<List<DatingCandidate>> candidates({
    required String accessToken,
    int limit = 10,
  }) async {
    if (accessToken.isEmpty || limit < 1 || limit > 10) {
      throw ArgumentError('Session required and limit must be 1..10');
    }
    final response = await _http.get(
      _uri('/v1/dating/candidates', {'limit': '$limit'}),
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw StateError('Dating unavailable');
    }
    if (response.statusCode != 200) {
      throw StateError('API Gateway unavailable');
    }
    final value = jsonDecode(response.body);
    if (value is! Map || value['items'] is! List) {
      throw const FormatException('Invalid API response');
    }
    return (value['items'] as List)
        .map((item) => DatingCandidate.fromJson(
            Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  void close() => _http.close();
}

class DatingCandidate {
  const DatingCandidate({
    required this.id,
    required this.displayName,
    required this.city,
    required this.sports,
  });

  final String id;
  final String displayName;
  final String city;
  final List<String> sports;

  factory DatingCandidate.fromJson(Map<String, dynamic> value) {
    return DatingCandidate(
      id: value['id'] as String,
      displayName: value['display_name'] as String,
      city: value['city'] as String,
      sports: List<String>.from(value['sports'] as List),
    );
  }
}
