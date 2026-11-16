/// Private FitDating readiness. Server JWT and RLS remain authoritative.
abstract class DatingRepositoryB5 {
  Future<Map<String,dynamic>> datingStatus();
  Future<void> acceptDating();
  Future<List<Map<String,dynamic>>> datingCandidates();
  Future<String> saveDatingPreferences(Map<String,dynamic> draft);
  Future<String> disableDating();
}
