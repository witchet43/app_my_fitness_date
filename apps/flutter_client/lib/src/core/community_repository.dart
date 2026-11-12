/// B4 social capabilities are gated independently from Dating or private gyms.
/// Implementations use the member JWT; SQL rechecks auth, consent and ownership.
abstract class CommunityRepository {
  Future<String> communityStatus();
  Future<void> acceptCommunityConsent();
  Future<String> setCommunityParticipation({required bool enabled});
  Future<List<Map<String, dynamic>>> communityFeed({DateTime? before});
  Future<String> publishCommunityPost(String topic, String content);
  Future<String> removeCommunityPost(String postId);
  Future<String> setCommunityBlock(String memberId, {required bool blocked});
  Future<List<Map<String, dynamic>>> communityBlocks();
  Future<String> reportCommunity({
    String? postId,
    String? userId,
    required String reason,
    String detail,
  });
  Future<List<Map<String, dynamic>>> myCommunityPosts();
  Future<String> communityDeletionStatus();
  Future<String> requestCommunityDeletion();

  /// Owner AAL2 only. Reporter identities are not returned to the UI.
  Future<List<Map<String, dynamic>>> adminCommunityAnnouncements();
  Future<String> adminPublishCommunityAnnouncement(String topic, String content);
  Future<String> adminRemoveCommunityAnnouncement(String postId);
  Future<List<Map<String, dynamic>>> pilotMembers();
  Future<String> admitPilotMember(String email);
  Future<String> revokePilotMember(String userId);
  Future<List<Map<String, dynamic>>> moderationReports();
  Future<String> resolveModerationReport({
    required String reportId,
    required String action,
    required String note,
  });
  Future<List<Map<String, dynamic>>> moderationDeletionRequests();
}
