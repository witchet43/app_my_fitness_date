import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/auth_refresh_policy.dart';
import 'package:my_fitness_date/src/features/brand_admin_mfa.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Factor factor({
  required String id,
  required FactorStatus status,
  required String? name,
  FactorType type = FactorType.totp,
}) => Factor(
  id:id, friendlyName:name, factorType:type, status:status,
  createdAt:DateTime.utc(2026,11,12), updatedAt:DateTime.utc(2026,11,12),
);

void main() {
  test('MFA detects pending setup in ALL factors and never deletes verified', () {
    final pending=factor(id:'pending',status:FactorStatus.unverified,
      name:brandAdminFactorName);
    final verified=factor(id:'verified',status:FactorStatus.verified,
      name:brandAdminFactorName);
    final unrelated=factor(id:'unrelated',status:FactorStatus.unverified,
      name:'Another app');
    final phone=factor(id:'phone',status:FactorStatus.unverified,
      name:brandAdminFactorName,type:FactorType.phone);
    final all=[pending, verified, unrelated, phone];
    expect(staleBrandAdminTotpFactors(all).map((f)=>f.id).toList(),
      ['pending']);
    expect(verifiedAdminTotpFactors(all).map((f)=>f.id).toList(),
      ['verified']);
    // Supabase's .totp list may be empty until enrollment is completed.
    // The pending factor must still be located through .all.
    expect(staleBrandAdminTotpFactors(<Factor>[]),isEmpty);
  });

  test('token rotation does not trigger a recursive identity/MFA refresh', () {
    expect(shouldRefreshIdentityForAuthEvent(AuthChangeEvent.tokenRefreshed),
      isFalse);
    expect(shouldRefreshIdentityForAuthEvent(AuthChangeEvent.signedIn),isTrue);
    expect(shouldRefreshIdentityForAuthEvent(AuthChangeEvent.signedOut),isTrue);
    expect(shouldRefreshIdentityForAuthEvent(AuthChangeEvent.passwordRecovery),
      isTrue);
  });
}
