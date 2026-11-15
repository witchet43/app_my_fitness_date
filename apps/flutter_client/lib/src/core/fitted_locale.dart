import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A display preference, NEVER an authorization signal.
/// Supabase Auth stores the preference in the signed-in user's metadata.
class FittedLocaleController extends ChangeNotifier {
  FittedLocaleController(this.client) {
    final stored=client.auth.currentUser?.userMetadata?['preferred_language'];
    _language=stored=='en'?'en':'es';
  }
  final SupabaseClient client;
  String _language='es';
  String get language=>_language;
  Locale get locale=>Locale(_language);
  bool get english=>_language=='en';

  Future<void> choose(String code) async {
    if(code!='es' && code!='en')throw ArgumentError('Unsupported language');
    if(code==_language)return;
    final prior=_language;
    _language=code;
    notifyListeners();
    if(client.auth.currentSession==null)return;
    try {
      await client.auth.updateUser(UserAttributes(
        data:{'preferred_language':code},
      ));
    }catch(_){
      _language=prior;
      notifyListeners();
      rethrow;
    }
  }
  void syncFromSession() {
    final stored=client.auth.currentUser?.userMetadata?['preferred_language'];
    final next=stored=='en'?'en':'es';
    if(next==_language)return;
    _language=next; notifyListeners();
  }
}

class FittedLocaleScope extends InheritedNotifier<FittedLocaleController> {
  const FittedLocaleScope({
    super.key,
    required FittedLocaleController controller,
    required super.child,
  }):super(notifier:controller);

  static FittedLocaleController? maybeOf(BuildContext context)=>
    context.dependOnInheritedWidgetOfExactType<FittedLocaleScope>()?.notifier;
  static String languageOf(BuildContext context)=>
    maybeOf(context)?.language??'es';
  static String t(BuildContext context,String es,String en)=>
    languageOf(context)=='en'?en:es;
}

class FittedLanguageSelector extends StatelessWidget {
  const FittedLanguageSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final ctrl=FittedLocaleScope.maybeOf(context);
    if(ctrl==null)return const SizedBox.shrink();
    return Semantics(
      label:'Language / Idioma',
      child:DropdownButton<String>(
        key:const Key('fitted-language-selector'),
        value:ctrl.language,
        underline:const SizedBox.shrink(),
        items:const [
          DropdownMenuItem(value:'es',child:Text('ES')),
          DropdownMenuItem(value:'en',child:Text('EN')),
        ],
        onChanged:(v)async{
          if(v==null)return;
          try {
            await ctrl.choose(v);
          }catch(_){
            if(context.mounted){
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(content:Text(
                  'No se pudo guardar el idioma / Could not save language')));
            }
          }
        },
      ),
    );
  }
}
