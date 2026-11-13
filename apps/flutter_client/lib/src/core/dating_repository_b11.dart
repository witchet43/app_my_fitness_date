import 'dating_repository_b5.dart';

/// Business operations use the authenticated member API. Every candidate,
/// message and mutual match is rechecked server-side; this interface must
/// never be implemented with local synthetic candidates in production.
abstract class DatingRepositoryB11 implements DatingRepositoryB5 {
  Future<Map<String,dynamic>?> loadRhythmB11();
  Future<void> saveRhythmB11(Map<String,dynamic> draft);
  /// Released catalog only; returned venue selection is always private.
  Future<List<Map<String,dynamic>>> gymCatalogB11();
  Future<String> activateB11(String gymId,List<Map<String,int>> weeklySlots);
  Future<List<Map<String,dynamic>>> discoverB11();
  Future<String> likeB11(String userId);
  Future<List<Map<String,dynamic>>> matchesB11();
  Future<List<Map<String,dynamic>>> messagesB11(String matchId);
  Future<String> sendB11(String matchId,String message);
  Future<String> reportB11(String matchId,String reason,{String detail=''});
  Future<List<String>> ideasB11(String matchId);
}
