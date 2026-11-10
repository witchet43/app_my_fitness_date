import 'dart:convert';

import 'package:http/http.dart' as http;

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

  /// Requires an access token provided by the future identity/session module.
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
