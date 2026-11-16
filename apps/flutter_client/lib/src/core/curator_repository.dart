/// B2 only: AAL2 owner curation without assuming a member profile.
/// All actions are authorized by the database, never by client role flags.
abstract class CuratorRepository {
  Future<List<Map<String, dynamic>>> adminActivities();
  Future<Map<String, dynamic>> adminPublishActivity(
    Map<String, dynamic> activity,
  );
  Future<String> adminCancelActivity(String eventId);
}
