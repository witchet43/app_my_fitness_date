import 'package:supabase_flutter/supabase_flutter.dart';

/// Only transitions that can change the logged-in identity or recovery flow
/// require a remote role check. Token rotation does NOT need to remount MFA.
bool shouldRefreshIdentityForAuthEvent(AuthChangeEvent event) =>
    event == AuthChangeEvent.signedIn ||
    event == AuthChangeEvent.signedOut ||
    event == AuthChangeEvent.passwordRecovery ||
    event == AuthChangeEvent.userUpdated;
