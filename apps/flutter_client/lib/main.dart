import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/core/api_client.dart';
import 'src/core/member_v26_api.dart';
import 'src/features/public_entry_shell.dart';
import 'src/member_v26_app.dart';
import 'src/theme/fitness_date_theme.dart';

/// A SINGLE coordinated V26 release. No partial production activation:
/// if the identity/consent/backend configuration is incomplete, the new
/// release stays on a marketing-only, fail-closed entry screen.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const v26=bool.fromEnvironment('MFD_V26_ENABLED',defaultValue:false);
  if(!v26){
    runApp(FitnessDateApp(api:ApiClient()));
    return;
  }

  // Existing Supabase project (formerly labeled DEV) is the intended PROD.
  // Its project ref is immutable; activation still needs OAuth, legal and API gates.
  const supabaseUrl=String.fromEnvironment('MFD_PROD_SUPABASE_URL');
  const publishableKey=String.fromEnvironment(
      'MFD_PROD_SUPABASE_PUBLISHABLE_KEY');
  const apiUrl=String.fromEnvironment('MFD_API_BASE_URL');
  const termsUrl=String.fromEnvironment('MFD_TERMS_URL');
  const privacyUrl=String.fromEnvironment('MFD_PRIVACY_URL');
  const termsVersion=String.fromEnvironment('MFD_TERMS_VERSION');
  const privacyVersion=String.fromEnvironment('MFD_PRIVACY_VERSION');
  const redirectUrl=String.fromEnvironment('MFD_OAUTH_REDIRECT_URL');
  const providerVerified=bool.fromEnvironment(
      'MFD_GOOGLE_PROVIDER_VERIFIED',defaultValue:false);

  final ready=
      supabaseUrl == 'https://jtrdvnwbxpfdnbzasvcj.supabase.co' &&
      publishableKey.startsWith('sb_publishable_') &&
      apiUrl.startsWith('https://') &&
      termsUrl.startsWith('https://') &&
      privacyUrl.startsWith('https://') &&
      redirectUrl.startsWith('https://') &&
      termsVersion.isNotEmpty && privacyVersion.isNotEmpty;
  if(!ready){
    runApp(MaterialApp(
      title:'My Fitness Date',
      debugShowCheckedModeBanner:false,
      theme:FitDateTheme.dark(),
      home:const PublicEntryShell(),
    ));
    return;
  }

  await Supabase.initialize(
    url:supabaseUrl,
    publishableKey:publishableKey,
    authOptions:const FlutterAuthClientOptions(
      authFlowType:AuthFlowType.pkce,
    ),
  );
  final supabase=Supabase.instance.client;
  runApp(MemberV26App(
    auth:supabase,
    api:MemberV26Api(gatewayUrl:apiUrl,auth:supabase),
    termsUrl:termsUrl,
    privacyUrl:privacyUrl,
    termsVersion:termsVersion,
    privacyVersion:privacyVersion,
    redirectUrl:redirectUrl,
    googleEnabled:providerVerified,
  ));
}
