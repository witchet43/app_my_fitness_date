import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Business data travels through our own FastAPI Gateway, not directly
/// through a privileged database key or user-selected identity.
class MemberV26Api {
  MemberV26Api({required this.gatewayUrl, required this.auth});

  final String gatewayUrl;
  final SupabaseClient auth;

  Future<http.Response> _request(String method, String path, {
    Map<String, dynamic>? data,
    Uint8List? body,
    String? contentType,
  }) async {
    final token = auth.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw const MemberApiException('Debes iniciar sesión.');
    }
    final uri = Uri.parse('$gatewayUrl$path');
    if (uri.scheme != 'https') {
      throw const MemberApiException('La conexión segura no está disponible.');
    }
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': contentType ?? 'application/json',
      'Cache-Control': 'no-store',
    };
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) {
      request.bodyBytes = body;
    } else if (data != null) {
      request.body = jsonEncode(data);
    }
    try {
      final result = await http.Client().send(request)
          .timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(result);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const MemberApiException('Tu sesión no tiene acceso a esta información.');
      }
      if (response.statusCode == 429) {
        throw const MemberApiException('Inténtalo de nuevo más tarde.');
      }
      throw const MemberApiException('Servicio temporalmente no disponible.');
    } on MemberApiException {
      rethrow;
    } catch (_) {
      throw const MemberApiException('No se pudo establecer una conexión segura.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) return body;
    } catch (_) {}
    throw const MemberApiException('Respuesta inesperada del servidor.');
  }

  Future<Map<String, dynamic>?> loadProfile() async {
    final value = _decode(await _request('GET', '/v1/me/profile'))['profile'];
    return value is Map<String, dynamic> ? value : null;
  }

  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> profile) async {
    final result = _decode(await _request('PUT', '/v1/me/profile', data: profile));
    return result['profile'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> loadPlaces() async {
    final body = _decode(await _request('GET', '/v1/me/places'));
    return (body['places'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<void> addPlace(Map<String, dynamic> place) async {
    await _request('POST', '/v1/me/places', data: place);
  }

  Future<void> removePlace(String id) async {
    await _request('DELETE', '/v1/me/places/$id');
  }

  Future<List<Map<String, dynamic>>> loadConsents() async {
    final body = _decode(await _request('GET', '/v1/me/consents'));
    return (body['consents'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<void> acceptConsent(String kind, String version) async {
    await _request('POST', '/v1/me/consents',
        data: {'consent_kind': kind, 'document_version': version});
  }

  Future<List<Map<String, dynamic>>> loadPhotos() async {
    final body = _decode(await _request('GET', '/v1/me/photos'));
    return (body['photos'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<void> uploadPhoto(Uint8List bytes, String contentType) async {
    await _request('POST', '/v1/me/photos',
        body: bytes, contentType: contentType);
  }

  Future<Uint8List> photoContent(String id) async {
    final resp = await _request('GET', '/v1/me/photos/$id/content');
    return resp.bodyBytes;
  }

  Future<void> removePhoto(String id) async {
    await _request('DELETE', '/v1/me/photos/$id');
  }
}

class MemberApiException implements Exception {
  const MemberApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
