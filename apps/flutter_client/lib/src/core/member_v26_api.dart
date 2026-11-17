import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'activity_repository.dart';
import 'curator_repository.dart';
import 'community_repository.dart';
import 'dating_repository_b11.dart';
import 'fit_ia_repository.dart';

/// Business data travels through our authenticated Supabase Edge gateway,
/// using the member JWT and RLS, never a privileged database key.
class MemberV26Api implements ActivityRepository, CuratorRepository, CommunityRepository, DatingRepositoryB11, FitIaRepository {
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
    const localQa=bool.fromEnvironment('MFD_LOCAL_QA',defaultValue:false);
    final loopbackAllowed=localQa &&
        Uri.base.scheme=='http' && Uri.base.host=='127.0.0.1' &&
        uri.scheme=='http' && uri.host=='127.0.0.1' && uri.port==54321;
    if(uri.scheme!='https'&&!loopbackAllowed){
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



  /// Fit-IA is a private, JWT-authenticated Edge Function. No service-role
  /// credentials or other members' data ever reach this application.
  Future<Map<String,dynamic>> _fitIa(String action,
      [Map<String,dynamic> args=const {}])async{
    if(auth.auth.currentSession?.accessToken==null){
      throw const MemberApiException('Inicia sesión para conversar con Fit-IA.');
    }
    try{
      final result=await auth.functions.invoke('fit-ia-v1',
        body:{'action':action,...args}).timeout(
          Duration(seconds:action=='summary'?40:25));
      if(result.status!=200){
        throw const MemberApiException(
          'Fit-IA no está disponible. Tus respuestas guardadas permanecen seguras.');
      }
      final raw=result.data;
      if(raw is Map){
        return Map<String,dynamic>.from(raw);
      }
      if(raw is String){
        final parsed=jsonDecode(raw);
        if(parsed is Map)return Map<String,dynamic>.from(parsed);
      }
      throw const MemberApiException('Fit-IA devolvió una respuesta inesperada.');
    }on MemberApiException{rethrow;}
    on FunctionException catch(e){
      if(e.status==401)throw const MemberApiException(
        'Tu sesión venció. Vuelve a iniciar sesión para conversar.');
      if(e.status==403)throw const MemberApiException(
        'No tienes permiso para abrir esta conversación.');
      if(e.status==409)throw const MemberApiException(
        'La pregunta cambió. Recarga la conversación para continuar.');
      if(e.status==429)throw const MemberApiException(
        'Fit-IA alcanzó el límite temporal de solicitudes.');
      throw const MemberApiException(
        'Fit-IA no respondió correctamente. Intenta actualizar la pantalla.');
    }catch(_){
      throw const MemberApiException(
        'No se pudo establecer conexión con Fit-IA. '
        'Verifica tu red o actualiza la página.');
    }
  }

  @override
  Future<Map<String,dynamic>> fitIaState(String pillar)=>
      _fitIa('state',{'pillar':pillar});
  @override
  Future<Map<String,dynamic>> fitIaAnswer(
      String pillar,String questionId,String choiceKey,{String locale='es'})=>
      _fitIa('answer',{
        'pillar':pillar,'question_id':questionId,'choice_key':choiceKey,
        'locale':locale,
      });
  @override
  Future<Map<String,dynamic>> fitIaOverview()=>_fitIa('overview');
  @override
  Future<Map<String,dynamic>> fitIaChatState(String pillar,
      {String locale='es'})=>
      _fitIa('chat_state',{'pillar':pillar,'locale':locale});
  @override
  Future<Map<String,dynamic>> fitIaChatSend(
      String pillar,String text,String clientId,{String locale='es'})=>
      _fitIa('chat_send',{
        'pillar':pillar,'text':text,'client_id':clientId,'locale':locale,
      });
  @override
  Future<Map<String,dynamic>> fitIaChatRetry(String pillar,
      {String locale='es'})=>
      _fitIa('chat_retry',{'pillar':pillar,'locale':locale});
  @override
  Future<Map<String,dynamic>> fitIaChatOlder(String pillar,int before)=>
      _fitIa('chat_older',{'pillar':pillar,'before':before});
  @override
  Future<Map<String,dynamic>> fitIaForm(String pillar)=>
      _fitIa('form',{'pillar':pillar});
  @override
  Future<Map<String,dynamic>> fitIaSubmitForm(
      String pillar,List<Map<String,String>> answers)=>
      _fitIa('form_submit',{'pillar':pillar,'answers':answers});
  @override
  Future<Map<String,dynamic>> fitIaInsights(String pillar)=>
      _fitIa('insights',{'pillar':pillar});
  @override
  Future<Map<String,dynamic>> fitIaConsent(bool enabled)async{
    // Both gates must agree: the account-wide AI permission and Fit-IA's
    // separate private conversation permission. Neither is inferred.
    await setFittedAiAccountPreference(enabled,source:'settings');
    return _fitIa('consent',{'enabled':enabled});
  }
  @override
  Future<Map<String,dynamic>> fitIaGenerateSummary()=>_fitIa('summary');
  @override
  Future<void> fitIaDeleteMyData()async{
    final result=await _fitIa('delete');
    if(result['status']!='deleted'){
      throw const MemberApiException('No se pudieron borrar tus respuestas.');
    }
  }

  // B18 safe summary: direct, authenticated owner-only RPC.
  /// One auditable account-level preference shared by every generative AI tool.
  Future<Map<String,dynamic>> fittedAiAccountPreference() async{
    final value=await auth.rpc('fitted_ai_account_preference_v1')
      .timeout(const Duration(seconds:12));
    return Map<String,dynamic>.from(value as Map);
  }

  Future<Map<String,dynamic>> setFittedAiAccountPreference(bool enabled,
      {required String source}) async{
    if(!const ['onboarding','settings'].contains(source)){
      throw const MemberApiException('Origen de preferencia IA inválido.');
    }
    final value=await auth.rpc('fitted_set_ai_account_preference_v1',
      params:{'p_enabled':enabled,'p_source':source})
      .timeout(const Duration(seconds:12));
    final result=Map<String,dynamic>.from(value as Map);
    if(result['configured']!=true || result['status']!='saved'&&
       result['status']!='already_configured'){
      throw const MemberApiException('No fue posible guardar la preferencia.');
    }
    return result;
  }

  Future<Map<String,dynamic>> myFittedSummaryB18() async {
    final raw=await auth.rpc('fitted_my_summary_b17');
    return raw is Map?Map<String,dynamic>.from(raw):<String,dynamic>{};
  }

  Future<String> fittedSummaryConsentB18({
    required bool ai,required bool share,
  }) async=>(await auth.rpc('fitted_summary_consent_b17',
    params:{'p_ai':ai,'p_share':share}))?.toString()??'not_available';

  /// Best effort; base editorial SQL summaries update immediately on save.
  /// The private AI function only accepts the owner's JWT after opt-in.
  Future<bool> refreshFittedAiSummaryB18() async{
    try {
      final summary=await myFittedSummaryB18();
      if(summary['ai_consented']!=true)return false;
      final response=await auth.functions.invoke(
        'fitted-ai-summary-b18',
        body:{'action':'refresh'},
      );
      return response.status==200 &&
        response.data is Map &&
        (response.data as Map)['status']=='saved';
    }catch(_){return false;}
  }

  /// Manually authored text is only accepted while AI consent is off.
  /// It is never sent to any AI service.
  Future<String> saveManualStoryB19({
    required String text, required String locale,
  }) async {
    if(!const ['es','en'].contains(locale) ||
       text.trim().length<80 || text.trim().length>1600){
      throw const MemberApiException(
        'Escribe entre 80 y 1600 caracteres en tu presentación.');
    }
    return (await auth.rpc('fitted_save_manual_summary_b19',params:{
      'p_text':text.trim(),'p_locale':locale,
    }))?.toString()??'not_available';
  }

  Future<Map<String,dynamic>> candidateShowcaseB18(String id) async {
    if(!_validActivityId(id))return <String,dynamic>{'available':false};
    final raw=await auth.rpc('fitted_candidate_showcase_b18',
      params:{'p_user':id});
    return raw is Map?Map<String,dynamic>.from(raw):<String,dynamic>{};
  }

  Future<Uint8List> candidatePhotoB18(String path) async {
    if(!RegExp(
      r'^[0-9a-f-]{36}/[a-zA-Z0-9_./-]+$',
      caseSensitive:false).hasMatch(path)){
      throw const MemberApiException('Fotografía no autorizada.');
    }
    // Storage RLS verifies eligible audience and approval again.
    return auth.storage.from('mfd-profile-private').download(path);
  }

  Future<Map<String, dynamic>?> loadProfile() async {
    final value = _decode(await _request('GET', '/v1/me/profile'))['profile'];
    return value is Map<String, dynamic> ? value : null;
  }

  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> profile) async {
    final result = _decode(await _request('PUT', '/v1/me/profile', data: profile));
    await refreshFittedAiSummaryB18();
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
    await refreshFittedAiSummaryB18();
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
  Future<Map<String,dynamic>> compatibilityB11(String userId) async {
    if (!_validActivityId(userId)) {
      throw const MemberApiException('Perfil inválido.');
    }
    return _decode(await _request('GET','/v1/dating/b11/score/$userId'));
  }

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
  Future<Map<String,dynamic>> pulseRealStatusB12(String matchId) async {
    if(!_validActivityId(matchId)) {
      throw const MemberApiException('Match inválido.');
    }
    return _decode(await _request('GET',
      '/v1/dating/b11/matches/$matchId/pulse/status'));
  }

  @override
  Future<String> setPulseRealConsentB12(bool accepted) async {
    return _decode(await _request('POST','/v1/dating/b11/pulse/consent',
      data:{'accepted':accepted}))['status']?.toString()??'not_available';
  }

  @override
  Future<String> confirmMeetupB12(String matchId) async {
    if(!_validActivityId(matchId)) {
      throw const MemberApiException('Match inválido.');
    }
    return _decode(await _request('POST',
      '/v1/dating/b11/matches/$matchId/pulse/confirm'))['status']?.toString()
      ?? 'not_available';
  }

  @override
  Future<String> submitPulseRealB12(
      String matchId,String dimension,String observation) async {
    if(!_validActivityId(matchId) ||
       !const ['move','live','relate'].contains(dimension) ||
       !const ['aligned','unclear','not_aligned'].contains(observation)) {
      throw const MemberApiException('Selecciona una evaluación válida.');
    }
    return _decode(await _request('POST',
      '/v1/dating/b11/matches/$matchId/pulse/observe',
      data:{'dimension':dimension,'observation':observation}))['status']
        ?.toString()??'not_available';
  }


  @override
  Future<List<Map<String,dynamic>>> myPulseObservationsB13() async =>
    _items(_decode(await _request('GET',
      '/v1/dating/pulse/my-observations')));

  @override
  Future<String> appealPulseObservationB13(
      String signalId,String statement) async {
    if(!_validActivityId(signalId) ||
        statement.trim().length<10 || statement.trim().length>500) {
      throw const MemberApiException('Explica tu apelación (10–500 caracteres).');
    }
    return _decode(await _request('POST','/v1/dating/pulse/appeal',
      data:{'signal_id':signalId,'statement':statement.trim()}))
      ['status']?.toString()??'not_available';
  }

  @override
  Future<String> retractPulseObservationB13(String signalId) async {
    if(!_validActivityId(signalId)){
      throw const MemberApiException('Evaluación inválida.');
    }
    return _decode(await _request('POST','/v1/dating/pulse/retract',
      data:{'signal_id':signalId}))['status']?.toString()??'not_available';
  }

  Future<List<Map<String,dynamic>>> adminPulseReviewQueueB13() async =>
    _items(_decode(await _request('GET','/v1/admin/pulse/reviews')));

  Future<String> adminResolvePulseSignalB13({
    required String signalId,required String decision,required String note,
  }) async {
    if(!_validActivityId(signalId) ||
        !const ['approve','reject','remove'].contains(decision) ||
        note.trim().length<5 || note.trim().length>500){
      throw const MemberApiException('Revisa la decisión y el motivo.');
    }
    return _decode(await _request('POST','/v1/admin/pulse/review',data:{
      'signal_id':signalId,'decision':decision,'note':note.trim(),
    }))['status']?.toString()??'not_available';
  }


  // B14: age requests use the authenticated user's JWT and private Storage RLS.
  Future<Map<String,dynamic>> ageReviewStatusB14() async =>
    Map<String,dynamic>.from(await auth.rpc('age_review_status_b14') as Map);

  Future<Map<String,dynamic>> ageBeginB14() async =>
    Map<String,dynamic>.from(await auth.rpc('age_start_review_b14',
      params:{'p_consent':true}) as Map);

  Future<String> ageSubmitB14(String requestId) async =>
    (await auth.rpc('age_submit_review_b14',params:{
      'p_request':requestId}))?.toString()??'not_available';

  Future<String> ageCancelB14() async =>
    (await auth.rpc('age_cancel_review_b14'))?.toString()??'not_available';

  Future<void> ageUploadB14({
    required String requestId,
    required String slot,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final me=auth.auth.currentUser?.id;
    if(me==null || !_validActivityId(requestId) ||
       !const ['document','selfie'].contains(slot) ||
       !const ['image/jpeg','image/png'].contains(contentType) ||
       bytes.isEmpty || bytes.length>5242880){
      throw const MemberApiException(
        'Documento inválido. Selecciona JPG o PNG de hasta 5 MB.');
    }
    await auth.storage.from('mfd-age-proof')
      .uploadBinary('$me/$requestId/$slot',bytes,
        fileOptions:FileOptions(contentType:contentType,upsert:true));
  }

  Future<List<Map<String,dynamic>>> adminAgeQueueB14() async {
    final values=await auth.rpc('admin_age_queue_b14');
    return (values as List).map((v)=>Map<String,dynamic>.from(v as Map)).toList();
  }

  Future<List<Map<String,dynamic>>> adminAgeErasureQueueB14() async {
    final values=await auth.rpc('admin_age_erasure_queue_b14');
    return (values as List).map((v)=>Map<String,dynamic>.from(v as Map)).toList();
  }

  Future<Uint8List> adminAgeEvidenceB14(String path) async {
    if(!RegExp(r'^[0-9a-f-]{36}/[0-9a-f-]{36}/(document|selfie)$',
       caseSensitive:false).hasMatch(path)){
      throw const MemberApiException('Referencia de evidencia inválida.');
    }
    return auth.storage.from('mfd-age-proof').download(path);
  }

  Future<String> adminAgeDecideB14({
    required String requestId,
    required String decision,
    DateTime? documentedBirthdate,
    DateTime? documentExpiry,
    required bool documentValid,
    required bool photoMatch,
    required String reason,
  }) async {
    if(!_validActivityId(requestId) ||
       !const ['approved','rejected'].contains(decision) ||
       reason.trim().length<10||reason.trim().length>500){
      throw const MemberApiException(
        'Completa una decisión y justificación válidas.');
    }
    String? day(DateTime? d){
      if(d==null)return null;
      final y=d.year.toString().padLeft(4,'0');
      final m=d.month.toString().padLeft(2,'0');
      final day=d.day.toString().padLeft(2,'0');
      return '$y-$m-$day';
    }
    return (await auth.rpc('admin_age_decide_b14',params:{
      'p_request':requestId,'p_decision':decision,
      'p_document_birthdate':day(documentedBirthdate),
      'p_document_valid':documentValid,'p_photo_match':photoMatch,
      'p_document_expiry':day(documentExpiry),'p_note':reason.trim(),
    }))?.toString()??'not_available';
  }

  Future<String> adminAgePurgeB14({
    required String requestId,
    required String documentPath,
    required String selfiePath,
  }) async {
    await auth.storage.from('mfd-age-proof')
      .remove([documentPath,selfiePath]);
    return (await auth.rpc('admin_age_mark_erased_b14',params:{
      'p_request':requestId}))?.toString()??'not_available';
  }

  Future<String> agePurgeOwnB14(String requestId) async {
    final me=auth.auth.currentUser?.id;
    if(me==null || !_validActivityId(requestId))return 'not_available';
    await auth.storage.from('mfd-age-proof')
      .remove(['$me/$requestId/document','$me/$requestId/selfie']);
    return 'removed';
  }

  Future<Map<String,dynamic>> manualDatingStatusB14() async =>
    Map<String,dynamic>.from(await auth.rpc('dating_manual_status_b14') as Map);

  Future<String> adminDatingLaunchB14({
    required bool enabled,
    required bool operatorAck,
    required bool privacyAck,
    required bool incidentAck,
    required String responsibility,
  }) async =>(await auth.rpc('admin_dating_launch_b14',params:{
    'p_enabled':enabled,'p_operator_ack':operatorAck,
    'p_privacy_ack':privacyAck,'p_incident_ack':incidentAck,
    'p_responsibility':responsibility,
  }))?.toString()??'not_available';

  Future<Map<String, dynamic>> datingStatus() async {
    final result=_decode(await _request('GET', '/v1/dating/status'));
    // The manual program is read from the server and never faked locally.
    try{
      final program=await manualDatingStatusB14();
      result['manual_document_review_ready']=program['enabled']==true;
    }catch(_){result['manual_document_review_ready']=false;}
    return result;
  }


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
