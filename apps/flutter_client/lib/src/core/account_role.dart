/// Route selection happens only after remote Supabase Auth has confirmed
/// identity and the database has independently confirmed the Brand Admin role.
/// Never infer administrative privileges from email, local profile or metadata.
enum AccountSpace {
  signedOut,
  member,
  administratorMfa,
  administrator,
  denied,
}

AccountSpace resolveAccountSpace({
  required bool hasSession,
  required bool remoteIdentityVerified,
  required bool roleCheckSucceeded,
  required bool brandAdministrator,
  required bool mfaAal2,
}) {
  if (!hasSession) return AccountSpace.signedOut;
  if (!remoteIdentityVerified || !roleCheckSucceeded) {
    return AccountSpace.denied;
  }
  if (brandAdministrator) {
    return mfaAal2 ? AccountSpace.administrator : AccountSpace.administratorMfa;
  }
  return AccountSpace.member;
}
