import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_fitness_date/src/core/community_repository.dart';
import 'package:my_fitness_date/src/features/community_b4.dart';
import 'package:my_fitness_date/src/features/community_moderation_b4.dart';
import 'package:my_fitness_date/src/features/community_pilot_b4.dart';

const memberId='bc8e3ef2-a487-46da-b3d1-d0747607a4bc';
const postId='2cb72a93-ef0c-4a91-ac22-675ee019d8c0';
const adminPostId='99a9c10d-8b4f-4bd0-baa0-7263f27cca2a';
const reportId='e8d92d40-b105-43b8-a966-e84dbd0c9b6f';

class FakeCommunityB4 implements CommunityRepository {
  bool consented = false;
  bool optedOut = false;
  bool blocked = false;
  bool deletion = false;
  bool removed = false;
  bool resolved = false;
  bool announcementRemoved = false;
  int publishedPosts = 0;
  int officialPublished = 0;
  int submittedReports = 0;
  String? lastModerationAction;
  bool pilotAdmitted=false;
  bool pilotRevoked=false;

  @override
  Future<String> communityStatus() async =>
    deletion ? 'deletion_pending'
      : optedOut ? 'opted_out'
      : consented ? 'available' : 'consent_required';

  @override
  Future<void> acceptCommunityConsent() async {
    consented = true;
  }

  @override
  Future<String> setCommunityParticipation({required bool enabled}) async {
    optedOut=!enabled;
    return enabled?'enabled':'disabled';
  }

  @override
  Future<List<Map<String, dynamic>>> communityFeed({
    DateTime? before,
  }) async {
    if(!consented || optedOut || before != null) return [];
    return [
      {
        'id':adminPostId,'author_id':'0be1d558-b761-4efc-9763-d9d6a36b76d4',
        'author_name':'Equipo My Fitness Date',
        'topic':'running','content':'Bienvenida a nuestra comunidad deportiva.',
        'is_mine':false,'is_official':true,
        'created_at':'2026-11-12T20:00:00Z',
      },
      if(!blocked && !removed)
        {
          'id':postId,'author_id':memberId,'author_name':'Persona Deportista',
          'topic':'hiking','content':'Caminata en grupo este fin de semana.',
          'is_mine':false,'is_official':false,
          'created_at':'2026-11-12T19:30:00Z',
        },
      if(publishedPosts>0)
        {
          'id':'d2d42877-f725-40dd-9a83-0e167e091715',
          'author_id':'7bea399f-61e0-4c3f-a7cc-4cf6e5b12009',
          'author_name':'Mi perfil','topic':'running',
          'content':'Compartí mi primer entrenamiento de running.',
          'is_mine':true,'is_official':false,
          'created_at':'2026-11-12T19:00:00Z',
        },
    ];
  }

  @override
  Future<String> publishCommunityPost(String topic,String content) async {
    expect(topic,'running');
    expect(content.length,greaterThanOrEqualTo(15));
    publishedPosts++;
    return 'published';
  }

  @override
  Future<String> removeCommunityPost(String id) async {
    removed=true;
    return 'removed';
  }

  @override
  Future<String> setCommunityBlock(String id,
      {required bool blocked}) async {
    expect(id,memberId);
    this.blocked=blocked;
    return blocked?'blocked':'unblocked';
  }

  @override
  Future<List<Map<String,dynamic>>> communityBlocks() async =>
    blocked ? [{'blocked_id':memberId,'display_name':'Persona Deportista'}] : [];

  @override
  Future<String> reportCommunity({
    String? postId,String? userId,
    required String reason,String detail='',
  }) async {
    expect(postId ?? userId,isNotNull);
    submittedReports++;
    return 'reported';
  }

  @override
  Future<List<Map<String,dynamic>>> myCommunityPosts() async => [];

  @override
  Future<String> communityDeletionStatus() async =>
    deletion ? 'pending' : 'none';

  @override
  Future<String> requestCommunityDeletion() async {
    deletion=true;
    return 'pending';
  }

  @override
  Future<List<Map<String,dynamic>>> pilotMembers() async =>
    pilotAdmitted ? [{
      'user_id':memberId,
      'email':'qa-member@example.invalid',
      'display_name':'Deportista QA',
      'active':!pilotRevoked,
      'admitted_at':'2026-11-12T20:00:00Z',
    }] : [];

  @override
  Future<String> admitPilotMember(String email) async {
    expect(email,'qa-member@example.invalid');
    pilotAdmitted=true;
    pilotRevoked=false;
    return 'admitted';
  }

  @override
  Future<String> revokePilotMember(String userId) async {
    expect(userId,memberId);
    pilotRevoked=true;
    return 'revoked';
  }

  @override
  Future<List<Map<String,dynamic>>> moderationReports() async =>
    resolved?[]:[{
      'id':reportId,'post_id':postId,'subject_id':memberId,
      'subject_name':'Persona Deportista','reason':'privacy',
      'detail':'Incluye una ubicación privada',
      'post_excerpt':'Caminata en grupo este fin de semana.',
      'created_at':'2026-11-12T21:00:00Z',
    }];

  @override
  Future<String> resolveModerationReport({
    required String reportId,
    required String action,
    required String note,
  }) async {
    expect(reportId,e8dReport);
    expect(note.length,greaterThanOrEqualTo(5));
    lastModerationAction=action;
    resolved=true;
    return 'resolved';
  }

  @override
  Future<List<Map<String,dynamic>>> moderationDeletionRequests() async =>
    deletion ? [{
      'user_id':memberId,
      'requested_at':'2026-11-12T21:00:00Z',
      'status':'pending',
    }] : [];

  @override
  Future<List<Map<String,dynamic>>> adminCommunityAnnouncements() async =>
    [{
      'id':adminPostId,'topic':'running',
      'content':'Bienvenida a nuestra comunidad deportiva.',
      'status':announcementRemoved ? 'removed':'visible',
      'created_at':'2026-11-12T20:00:00Z',
    }];

  @override
  Future<String> adminPublishCommunityAnnouncement(
      String topic,String content) async {
    officialPublished++;
    return 'published';
  }

  @override
  Future<String> adminRemoveCommunityAnnouncement(String postId) async {
    expect(postId,adminPostId);
    announcementRemoved=true;
    return 'removed';
  }
}
const e8dReport=reportId;

void main() {
  testWidgets('community is opt-in; no feed until separate legal consent',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080,900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake=FakeCommunityB4();
    await tester.pumpWidget(MaterialApp(home:CommunityB4(api:fake)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b4-consent-submit')),findsOneWidget);
    expect(find.byKey(const Key('b4-post-$postId')),findsNothing);
    await tester.tap(find.byKey(const Key('b4-consent-submit')));
    await tester.pumpAndSettle();
    expect(fake.consented,isTrue);
    expect(find.text('Equipo My Fitness Date'),findsOneWidget);
    expect(find.text('Persona Deportista'),findsOneWidget);
    expect(find.byKey(const Key('b4-create-post')),findsOneWidget);
    expect(tester.takeException(),isNull);
  });

  testWidgets('blocking hides member author but retains official notice',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080,900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake=FakeCommunityB4()..consented=true;
    await tester.pumpWidget(MaterialApp(home:CommunityB4(api:fake)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('b4-post-actions-$postId')));
    await tester.tap(find.byKey(const Key('b4-post-actions-$postId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bloquear persona'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('b4-block-confirm')));
    await tester.pumpAndSettle();
    expect(fake.blocked,isTrue);
    expect(find.byKey(const Key('b4-post-$postId')),findsNothing);
    expect(find.text('Equipo My Fitness Date'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });

  testWidgets('moderator resolves report with mandatory audit note',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100,900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake=FakeCommunityB4();
    await tester.pumpWidget(
      MaterialApp(home:CommunityModerationB4(api:fake)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b4-report-$reportId')),findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('b4-resolve-$reportId')));
    await tester.tap(find.byKey(const Key('b4-resolve-$reportId')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('b4-moderation-note')),
      'Se revisó la denuncia y no se observaron infracciones.');
    await tester.tap(find.byKey(const Key('b4-moderation-submit')));
    await tester.pumpAndSettle();
    expect(fake.resolved,isTrue);
    expect(fake.lastModerationAction,'dismiss');
    expect(find.byKey(const Key('b4-reports-empty')),findsOneWidget);
    expect(tester.takeException(),isNull);
  });

  testWidgets('deletion request is clearly human-reviewed, not erased',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080,900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake=FakeCommunityB4();
    await tester.pumpWidget(
      MaterialApp(home:CommunityPrivacyB4(api:fake)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('b4-delete-request')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(
      'Comprendo que es una solicitud, no un borrado inmediato.'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('b4-delete-request-confirm')));
    await tester.pumpAndSettle();
    expect(fake.deletion,isTrue);
    expect(find.textContaining('Solicitud de baja registrada'),
      findsOneWidget);
    expect(tester.takeException(),isNull);
  });
  testWidgets('owner can publish genuine official sports notices',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100,900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake=FakeCommunityB4();
    await tester.pumpWidget(
      MaterialApp(home:CommunityModerationB4(api:fake)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(
      const Key('b4-moderation-tab-announcements')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('b4-admin-new-announcement')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(
      const Key('b4-announcement-content')),
      'Este domingo tendremos una caminata deportiva abierta.');
    await tester.tap(find.byKey(const Key('b4-announcement-submit')));
    await tester.pumpAndSettle();
    expect(fake.officialPublished,1);
    expect(find.byKey(const Key('b4-announcements-empty')),findsNothing);
    expect(tester.takeException(),isNull);
  });


  testWidgets('member can leave and rejoin separately from account deletion',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080,900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake=FakeCommunityB4()..consented=true;
    await tester.pumpWidget(MaterialApp(home:CommunityB4(api:fake)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('b4-privacy-open')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('b4-community-leave')));
    await tester.tap(find.byKey(const Key('b4-community-leave')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('b4-community-leave-confirm')));
    await tester.pumpAndSettle();
    expect(fake.optedOut,isTrue);
    expect(fake.deletion,isFalse);
    expect(find.byKey(const Key('b4-community-rejoin')),findsOneWidget);
    await tester.tap(find.byKey(const Key('b4-community-rejoin')));
    await tester.pumpAndSettle();
    expect(fake.optedOut,isFalse);
    expect(find.byKey(const Key('b4-create-post')),findsOneWidget);
    expect(tester.takeException(),isNull);
  });


  testWidgets('owner can authorize and revoke closed-pilot member',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080,900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake=FakeCommunityB4();
    await tester.pumpWidget(MaterialApp(home:CommunityPilotB4(api:fake)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b4-pilot-empty')),findsOneWidget);
    await tester.tap(find.byKey(const Key('b4-pilot-invite')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('b4-pilot-email')),
      'qa-member@example.invalid');
    await tester.tap(find.byKey(const Key('b4-pilot-submit')));
    await tester.pumpAndSettle();
    expect(fake.pilotAdmitted,isTrue);
    await tester.ensureVisible(find.byKey(
      const Key('b4-pilot-revoke-$memberId')));
    await tester.tap(find.byKey(const Key('b4-pilot-revoke-$memberId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('b4-pilot-revoke-confirm')));
    await tester.pumpAndSettle();
    expect(fake.pilotRevoked,isTrue);
    expect(tester.takeException(),isNull);
  });


}
