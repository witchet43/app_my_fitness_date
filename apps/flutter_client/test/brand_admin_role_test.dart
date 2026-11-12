import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/account_role.dart';
import 'package:my_fitness_date/src/core/brand_admin_repository.dart';
import 'package:my_fitness_date/src/features/brand_admin_home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeBrandRepository extends BrandAdminRepository {
  FakeBrandRepository() : super(SupabaseClient('https://example.supabase.co','anon-test'));
  @override
  Future<List<Map<String, dynamic>>> loadPalettes() async => [
    {'id':'palette1','name':'Bosque','colors':{
      'primary':'#28463D','accent':'#B49A6A','background':'#F7F5F0'}}];
  @override
  Future<List<Map<String, dynamic>>> loadAssets() async => [];
  @override
  Future<List<Map<String, dynamic>>> loadDrafts() async => [];
}

void main() {
  test('roles are resolved from verified remote identity, never email', () {
    expect(resolveAccountSpace(hasSession:false,
      remoteIdentityVerified:false,roleCheckSucceeded:false,
      brandAdministrator:false,mfaAal2:false),AccountSpace.signedOut);
    expect(resolveAccountSpace(hasSession:true,
      remoteIdentityVerified:true,roleCheckSucceeded:false,
      brandAdministrator:false,mfaAal2:false),AccountSpace.denied);
    expect(resolveAccountSpace(hasSession:true,
      remoteIdentityVerified:false,roleCheckSucceeded:true,
      brandAdministrator:true,mfaAal2:true),AccountSpace.denied);
    expect(resolveAccountSpace(hasSession:true,
      remoteIdentityVerified:true,roleCheckSucceeded:true,
      brandAdministrator:false,mfaAal2:true),AccountSpace.member);
    expect(resolveAccountSpace(hasSession:true,
      remoteIdentityVerified:true,roleCheckSucceeded:true,
      brandAdministrator:true,mfaAal2:false),AccountSpace.administratorMfa);
    expect(resolveAccountSpace(hasSession:true,
      remoteIdentityVerified:true,roleCheckSucceeded:true,
      brandAdministrator:true,mfaAal2:true),AccountSpace.administrator);
  });

  test('custom palette input allows only six-digit hex colors', () {
    expect(BrandAdminRepository.validHex('#28463D'),isTrue);
    expect(BrandAdminRepository.validHex('#ff0000'),isTrue);
    expect(BrandAdminRepository.validHex('red'),isFalse);
    expect(BrandAdminRepository.validHex('#fff'),isFalse);
    expect(BrandAdminRepository.validHex('#ffffff;script'),isFalse);
  });

  testWidgets('Native admin dashboard uses member Flutter MaterialApp',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200,900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home:BrandAdminHome(
      repository:FakeBrandRepository(),
      email:'admin@example.invalid',
      onSignOut:() async {},
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('brand-admin-flutter-shell')),findsOneWidget);
    expect(find.text('Panel de Administración'),findsOneWidget);
    expect(find.text('FitDating'),findsNothing);
    await tester.tap(find.text('Configurar identidad'));
    await tester.pumpAndSettle();
    expect(find.text('Identidad de marca'),findsOneWidget);
    expect(find.byKey(const Key('admin-logo-0')),findsOneWidget);
    expect(find.byKey(const Key('admin-logo-9')),findsOneWidget);
    expect(find.byKey(const Key('admin-save-brand-draft')),findsOneWidget);
  });
}
