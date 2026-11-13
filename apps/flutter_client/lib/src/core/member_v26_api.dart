import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'activity_repository.dart';
import 'curator_repository.dart';
import 'community_repository.dart';
import 'dating_repository_b11.dart';

/// Business data travels through our own FastAPI Gateway, not directly
/// through a privileged database key or user-selected identity.
class MemberV26Api implements ActivityRepository, CuratorRepository, CommunityRepository, DatingRepositoryB11 {
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
    final client = http.Client();
    try {
      final result = await client.send(request)
          .timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(result);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      if (response.statusCode == 409) {
        final reason = _safeStatus(response.body);
        throw MemberApiException(reason == 'full'
          ? 'Los lugares de esta actividad se agotaron.'
          : reason == 'already_started'
            ? 'La actividad ya empezó y no admite cambios.'
            : 'Esta actividad ya no admite nuevas participaciones.');
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        final reason = _safeStatus(response.body);
        if (reason == 'profile_required') {
          throw const MemberApiException('Completa tu perfil antes de participar.');
        }
        if (reason == 'consent_required') {
          throw const MemberApiException('Acepta los términos y privacidad antes de participar.');
        }
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
    } finally {
      client.close();
    }
  }

  String? _safeStatus(String responseBody) {
    try {
      final parsed = jsonDecode(responseBody);
      return parsed is Map ? parsed['status']?.toString() : null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) return body;
    } catch (_) {}
    throw const MemberApiException('Respuesta inesperada del servidor.');
  }

  @override
  Future<List<Map<String, dynamic>>> loadActivities() async {
    final result = _decode(await _request('GET', '/v1/activities'));
    final values = result['items'];
    if (values is! List) {
      throw const MemberApiException('No se pudo leer el catálogo de actividades.');
    }
    return values.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  }

  @override
  Future<String> confirmActivity(String eventId) async {
    final valid = eventId.length == 36 &&
        RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')
          .firstMatch(eventId)?.group(0)?.length == 36;
    if (!valid) throw const MemberApiException('Actividad inválida.');
    final result = _decode(await _request(
      'POST', '/v1/activities/' + eventId + '/rsvp',
    ));
    final status = result['status']?.toString();
    if (status != 'confirmed' && status != 'already_confirmed') {
      throw const MemberApiException('No fue posible confirmar la participación.');
    }
    return status!;
  }

  @override
  Future<bool> isApprovedActivityOrganizer() async {
    final result = _decode(await _request('GET', '/v1/me/organizer-status'));
    return result['approved'] == true;
  }

  @override
  Future<Map<String, dynamic>> publishActivity(
      Map<String, dynamic> activity) async {
    final result = _decode(await _request(
      'POST', '/v1/organizer/activities', data: activity,
    ));
    return Map<String, dynamic>.from(result['activity'] as Map);
  }

  @override
  Future<List<Map<String, dynamic>>> loadMyActivities() async {
    final response = _decode(await _request('GET', '/v1/me/activities'));
    final values = response['items'];
    if (values is! List) {
      throw const MemberApiException('No se pudo consultar tu historial.');
    }
    return values.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  }

  @override
  Future<String> cancelActivity(String eventId) async {
    if (!_validActivityId(eventId)) {
      throw const MemberApiException('Actividad inválida.');
    }
    final response = _decode(await _request(
      'POST', '/v1/activities/$eventId/cancel',
    ));
    final status = response['status']?.toString();
    if (status != 'cancelled' && status != 'already_cancelled') {
      throw const MemberApiException('No fue posible cancelar tu participación.');
    }
    return status!;
  }

  @override
  Future<List<Map<String, dynamic>>> loadOrganizedActivities() async {
    final response = _decode(await _request(
      'GET', '/v1/organizer/activities',
    ));
    final values = response['items'];
    if (values is! List) {
      throw const MemberApiException('No se pudieron consultar tus eventos.');
    }
    return values.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  }

  @override
  Future<String> cancelOrganizedActivity(String eventId) async {
    if (!_validActivityId(eventId)) {
      throw const MemberApiException('Actividad inválida.');
    }
    final response = _decode(await _request(
      'POST', '/v1/organizer/activities/$eventId/cancel',
    ));
    final status = response['status']?.toString();
    if (status != 'cancelled' && status != 'already_cancelled') {
      throw const MemberApiException('No fue posible cancelar el evento.');
    }
    return status!;
  }

  bool _validActivityId(String value) =>
    RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
      .hasMatch(value);
  @override
  Future<List<Map<String, dynamic>>> adminActivities() async {
    final result = _decode(await _request('GET', '/v1/admin/activities'));
    final values = result['items'];
    if (values is! List) {
      throw const MemberApiException('No fue posible consultar los eventos.');
    }
    return values.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  }

  @override
  Future<Map<String, dynamic>> adminPublishActivity(
      Map<String, dynamic> activity) async {
    final result = _decode(await _request(
      'POST', '/v1/admin/activities', data: activity,
    ));
    return Map<String, dynamic>.from(result['activity'] as Map);
  }

  @override
  Future<String> adminCancelActivity(String eventId) async {
    if (!_validActivityId(eventId)) {
      throw const MemberApiException('Actividad inválida.');
    }
    final result = _decode(await _request(
      'POST', '/v1/admin/activities/$eventId/cancel',
    ));
    final status = result['status']?.toString();
    if (status != 'cancelled' && status != 'already_cancelled') {
      throw const MemberApiException('No fue posible cancelar el evento.');
    }
    return status!;
  }
  List<Map<String, dynamic>> _items(Map<String, dynamic> response) {
    final raw = response['items'];
    if (raw is! List) {
      throw const MemberApiException('El servicio respondió con datos inválidos.');
    }
    return raw.map((value) => Map<String, dynamic>.from(value as Map)).toList();
  }

  @override
  Future<String> communityStatus() async =>
    _decode(await _request('GET','/v1/community/status'))['status'].toString();

  @override
  Future<void> acceptCommunityConsent() async {
    await acceptConsent('community','community-v1');
  }

  @override
  Future<String> setCommunityParticipation({required bool enabled}) async =>
    _decode(await _request(
      'POST','/v1/me/community/participation',
      data:{'enabled':enabled}))['status'].toString();

  @override
  Future<List<Map<String, dynamic>>> communityFeed({DateTime? before}) async {
    final suffix=before==null?'':'?before=${Uri.encodeQueryComponent(
      before.toUtc().toIso8601String())}';
    return _items(_decode(await _request(
      'GET','/v1/community/feed$suffix')));
  }

  @override
  Future<String> publishCommunityPost(String topic,String content) async {
    final result=_decode(await _request('POST','/v1/community/posts',
      data:{'topic':topic,'content':content}));
    return result['status'].toString();
  }

  @override
  Future<String> removeCommunityPost(String postId) async {
    if(!_validActivityId(postId)) {
      throw const MemberApiException('Publicación inválida.');
    }
    final result=_decode(await _request(
      'DELETE','/v1/community/posts/$postId'));
    return result['status'].toString();
  }

  @override
  Future<String> setCommunityBlock(
      String memberId,{required bool blocked}) async {
    if(!_validActivityId(memberId)) {
      throw const MemberApiException('Cuenta inválida.');
    }
    final result=_decode(await _request('POST','/v1/community/block',
      data:{'user_id':memberId,'blocked':blocked}));
    return result['status'].toString();
  }

  @override
  Future<List<Map<String,dynamic>>> communityBlocks() async =>
    _items(_decode(await _request('GET','/v1/community/blocks')));

  @override
  Future<String> reportCommunity({
    String? postId,String? userId,
    required String reason,String detail='',
  }) async {
    final validPost=postId==null || _validActivityId(postId);
    final validUser=userId==null || _validActivityId(userId);
    if((postId==null)==(userId==null) || !validPost || !validUser) {
      throw const MemberApiException('Selecciona una publicación o perfil.');
    }
    final result=_decode(await _request('POST','/v1/community/report',data:{
      'post_id':postId,'user_id':userId,'reason':reason,'detail':detail}));
    return result['status'].toString();
  }

  @override
  Future<List<Map<String,dynamic>>> myCommunityPosts() async =>
    _items(_decode(await _request('GET','/v1/me/community/posts')));

  @override
  Future<String> communityDeletionStatus() async =>
    _decode(await _request('GET','/v1/me/community/deletion'))
      ['status'].toString();

  @override
  Future<String> requestCommunityDeletion() async =>
    _decode(await _request('POST','/v1/me/community/deletion'))
      ['status'].toString();

  @override
  Future<List<Map<String,dynamic>>> adminCommunityAnnouncements() async =>
    _items(_decode(await _request(
      'GET','/v1/admin/community/announcements')));

  @override
  Future<String> adminPublishCommunityAnnouncement(
      String topic,String content) async =>
    _decode(await _request(
      'POST','/v1/admin/community/announcements',
      data:{'topic':topic,'content':content}))['status'].toString();

  @override
  Future<String> adminRemoveCommunityAnnouncement(String postId) async {
    if(!_validActivityId(postId)) {
      throw const MemberApiException('Comunicado inválido.');
    }
    return _decode(await _request(
      'DELETE','/v1/admin/community/announcements/$postId'))
      ['status'].toString();
  }

  @override
  Future<List<Map<String,dynamic>>> pilotMembers() async =>
    _items(_decode(await _request('GET','/v1/admin/community/pilot')));

  @override
  Future<String> admitPilotMember(String email) async =>
    _decode(await _request('POST','/v1/admin/community/pilot',
      data:{'email':email.trim()}))['status'].toString();

  @override
  Future<String> revokePilotMember(String userId) async {
    if(!_validActivityId(userId)) {
      throw const MemberApiException('Identificador inválido.');
    }
    return _decode(await _request(
      'POST','/v1/admin/community/pilot/revoke',
      data:{'user_id':userId}))['status'].toString();
  }

  @override
  Future<List<Map<String,dynamic>>> moderationReports() async =>
    _items(_decode(await _request('GET','/v1/admin/community/reports')));

  @override
  Future<String> resolveModerationReport({
    required String reportId,
    required String action,
    required String note,
  }) async {
    if(!_validActivityId(reportId)) {
      throw const MemberApiException('Reporte inválido.');
    }
    final result=_decode(await _request(
      'POST','/v1/admin/community/resolve',data:{
        'report_id':reportId,'action':action,'note':note}));
    return result['status'].toString();
  }

  @override
  Future<List<Map<String,dynamic>>> moderationDeletionRequests() async =>
    _items(_decode(await _request('GET','/v1/admin/community/deletions')));

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


  @override
  Future<Map<String,dynamic>?> loadRhythmB11() async {
    final data=_decode(await _request('GET','/v1/dating/rhythm'));
    final profile=data['profile'];
    return profile is Map ? Map<String,dynamic>.from(profile) : null;
  }

  @override
  Future<void> saveRhythmB11(Map<String,dynamic> draft) async {
    _decode(await _request('PUT','/v1/dating/rhythm',data:draft));
  }

  @override
  Future<List<Map<String,dynamic>>> gymCatalogB11() async =>
    _items(_decode(await _request('GET','/v1/dating/b11/gyms')));

  @override
  Future<String> activateB11(
      String gymId,List<Map<String,int>> weeklySlots) async {
    if(!_validActivityId(gymId) || weeklySlots.length>14) {
      throw const MemberApiException('Selecciona un gimnasio válido.');
    }
    for(final slot in weeklySlots){
      final day=slot['day'];
      final start=slot['startMinutes'];
      final end=slot['endMinutes'];
      if(day==null||day<0||day>6||start==null||start<0||
         end==null||end>1440||start>=end){
        throw const MemberApiException('Revisa tus horarios privados.');
      }
    }
    final value=_decode(await _request(
      'POST','/v1/dating/b11/activate',
      data:{'gym_id':gymId,'weekly_slots':weeklySlots}));
    if(value['status']!='activated'){
      throw const MemberApiException(
        'No fue posible activar el descubrimiento.');
    }
    return 'activated';
  }

  @override
  Future<List<Map<String,dynamic>>> discoverB11() async =>
    _items(_decode(await _request('GET','/v1/dating/b11/candidates')));

  @override
  Future<String> likeB11(String userId) async {
    if (!_validActivityId(userId)) {
      throw const MemberApiException('Perfil inválido.');
    }
    return _decode(await _request('POST','/v1/dating/b11/like',
      data:{'user_id':userId}))['status'].toString();
  }

  @override
  Future<List<Map<String,dynamic>>> matchesB11() async =>
    _items(_decode(await _request('GET','/v1/dating/b11/matches')));

  @override
  Future<List<Map<String,dynamic>>> messagesB11(String matchId) async {
    if(!_validActivityId(matchId)) {
      throw const MemberApiException('Match inválido.');
    }
    return _items(_decode(await _request('GET',
      '/v1/dating/b11/matches/$matchId/messages')));
  }

  @override
  Future<String> sendB11(String matchId,String message) async {
    if(!_validActivityId(matchId)||message.trim().isEmpty||
       message.length>1200) {
      throw const MemberApiException('Revisa el mensaje.');
    }
    return _decode(await _request('POST',
      '/v1/dating/b11/matches/$matchId/messages',
      data:{'body':message.trim()}))['status'].toString();
  }

  @override
  Future<String> reportB11(String matchId,String reason,
      {String detail=''}) async {
    if(!_validActivityId(matchId)||detail.length>500) {
      throw const MemberApiException('Reporte inválido.');
    }
    return _decode(await _request('POST',
      '/v1/dating/b11/matches/$matchId/report',
      data:{'reason':reason,'detail':detail}))['status'].toString();
  }

  @override
  Future<List<String>> ideasB11(String matchId) async {
    if(!_validActivityId(matchId)) {
      throw const MemberApiException('Match inválido.');
    }
    final result=_decode(await _request('GET',
      '/v1/dating/b11/matches/$matchId/ideas'));
    final values=result['items'];
    if(values is! List) {
      throw const MemberApiException('Sugerencias no disponibles.');
    }
    return values.map((x)=>x.toString()).toList();
  }

  @override
  Future<Map<String, dynamic>> datingStatus() async =>
      _decode(await _request('GET', '/v1/dating/status'));

  Future<void> acceptDating() async {
    await _request('POST', '/v1/dating/consent',
        data: {'opt_in': true});
  }

  @override
  Future<String> saveDatingPreferences(Map<String,dynamic> draft) async {
    final response = _decode(await _request(
      'POST','/v1/dating/preferences',data:draft,
    ));
    if (response['status'] != 'saved') {
      throw const MemberApiException('No fue posible guardar tus preferencias.');
    }
    return 'saved';
  }

  @override
  Future<String> disableDating() async {
    final response = _decode(await _request(
      'POST','/v1/dating/disable',
    ));
    if (response['status'] != 'disabled') {
      throw const MemberApiException('No pudimos desactivar FitDating.');
    }
    return 'disabled';
  }

  @override
  Future<List<Map<String, dynamic>>> datingCandidates() async {
    final response = _decode(await _request('GET', '/v1/dating/candidates'));
    return (response['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
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
