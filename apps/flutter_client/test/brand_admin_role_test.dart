import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/account_role.dart';
import 'package:my_fitness_date/src/core/brand_admin_repository.dart';
import 'package:my_fitness_date/src/core/live_brand.dart';
import 'package:my_fitness_date/src/features/brand_admin_home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeBrandRepository extends BrandAdminRepository {
  FakeBrandRepository() : super(SupabaseClient('https://example.supabase.co','anon-test')) {
    // Disable GoTrue's periodic 10-second refresh timer in fake-async tests.
    client.auth.stopAutoRefresh();
  }
  @override
  Future<List<Map<String, dynamic>>> loadPalettes() async => [
    {'id':'palette1','name':'Bosque','colors':{
      'primary':'#28463D','accent':'#B49A6A','background':'#F7F5F0'}}];
  @override
  Future<List<Map<String, dynamic>>> loadAssets() async => [];
  @override
  Future<List<Map<String, dynamic>>> loadDrafts() async => [];
}

class FakeLiveBrand extends LiveBrandController {
  int saveCalls=0;
  FakeLiveBrand(super.client) {
    loaded=true;
    current=LiveBrandSettings.fallback;
    version=0;
  }
  @override
  Future<void> refresh() async {}
  @override
  Future<void> save(LiveBrandSettings proposed)async{
    saveCalls++;
    current=proposed;
    version++;
    loaded=true;
    notifyListeners();
  }
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

  testWidgets('Changing designer settings never publishes before Save & publish',
      (tester)async{
    await tester.binding.setSurfaceSize(const Size(1200,900));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final repository=FakeBrandRepository();
    final live=FakeLiveBrand(repository.client);
    await tester.pumpWidget(MaterialApp(home:BrandAdminHome(
      repository:repository,liveBrand:live,
      email:'brand-admin@example.invalid',onSignOut:()async{})));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar marca en vivo'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('brand-publish-save')),findsWidgets);
    final brandField=find.widgetWithText(TextField,'Nombre de la aplicación');
    await tester.ensureVisible(brandField);
    await tester.enterText(brandField,'Fitted Preview Only');
    await tester.pump(const Duration(seconds:3));
    expect(live.saveCalls,0);
    expect(live.current.name,'Fitted');
    // The status sits above a lazily built scroll viewport; the no-save
    // assertion proves global isolation regardless of scroll position.
    // The long editor uses lazy ListView children; walk back to its header
    // without asking Flutter to resolve an offscreen Finder.first.
    for(var i=0;i<15 &&
        find.byKey(const Key('brand-publish-save')).evaluate().isEmpty;i++){
      await tester.drag(find.byType(ListView).first,const Offset(0,270));
      await tester.pump();
    }
    expect(find.byKey(const Key('brand-publish-save')),findsWidgets);
    await tester.tap(find.byKey(const Key('brand-publish-save')).first);
    await tester.pumpAndSettle();
    expect(live.saveCalls,1);
    expect(live.current.name,'Fitted Preview Only');
    expect(tester.takeException(),isNull);
  });

  testWidgets('Native admin dashboard uses member Flutter MaterialApp',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200,900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository=FakeBrandRepository();
    final liveBrand=FakeLiveBrand(repository.client);
    await tester.pumpWidget(MaterialApp(home:BrandAdminHome(
      repository:repository,
      liveBrand:liveBrand,
      email:'admin@example.invalid',
      onSignOut:() async {},
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('brand-admin-flutter-shell')),findsOneWidget);
    expect(find.text('Panel de Administración'),findsOneWidget);
    expect(find.text('FitDating'),findsNothing);
    await tester.tap(find.text('Editar marca en vivo'));
    await tester.pumpAndSettle();
    expect(find.text('Diseñador de Marca · Vista previa privada'),findsOneWidget);
    expect(find.byKey(const Key('brand-palette-selector')),findsOneWidget);
    expect(find.byKey(const Key('brand-color-primario')),findsOneWidget);
    expect(find.byKey(const Key('brand-logo-reel')),findsOneWidget);
    expect(find.byKey(const Key('admin-logo-0')),findsOneWidget);
    expect(find.byKey(const Key('b3-auto-publish-label')),findsOneWidget);
  });
}
