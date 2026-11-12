/// B1 business contract: UI and tests share this boundary.
/// Implementations must enforce identity, privacy and RSVP authority on server.
abstract class ActivityRepository {
  Future<List<Map<String, dynamic>>> loadActivities();
  Future<String> confirmActivity(String eventId);
  Future<bool> isApprovedActivityOrganizer();
  Future<Map<String, dynamic>> publishActivity(Map<String, dynamic> activity);
}
