import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/brand_admin_repository.dart';
import '../core/live_brand.dart';
import '../core/fitted_locale.dart';
import '../core/curator_repository.dart';
import '../core/activity_repository.dart';
import '../core/community_repository.dart';
import '../core/member_v26_api.dart';
import 'fitted_pulse_moderation_b13.dart';
import 'fitted_age_admin_b14.dart';
import 'community_moderation_b4.dart';
import 'gym_catalog_admin_b11.dart';
import 'match_calculator_admin.dart';
import 'activities_b1.dart';
import 'admin_curated_activities_b2.dart';
import '../widgets/mfd_branding.dart';
import '../widgets/fitted_logo_catalog.dart';
import '../widgets/fitted_color_picker.dart';
import '../widgets/fitted_font_catalog.dart';

/// Administration lives in the SAME Flutter application / MaterialApp as
/// member screens. Only the server-backed role gate may construct this view.
/// The repository and Supabase RLS require AAL2 for each operation.
class BrandAdminHome extends StatefulWidget {
  const BrandAdminHome({
    super.key,
    required this.repository,
    required this.email,
    required this.onSignOut,
    this.curatorApi,
    this.activityPreviewApi,
    this.communityAdmin,
    required this.liveBrand,
  });
  final BrandAdminRepository repository;
  final String email;
  final Future<void> Function() onSignOut;
  final CuratorRepository? curatorApi;
  final ActivityRepository? activityPreviewApi;
  final CommunityRepository? communityAdmin;
  final LiveBrandController liveBrand;

  @override
  State<BrandAdminHome> createState() => _BrandAdminHomeState();
}

class _BrandAdminHomeState extends State<BrandAdminHome> {
  static const _tabs = <String>[
    'Resumen', 'Diseñador de Marca', 'Calculadora del match', 'Biblioteca', 'Mis diseños', 'Historial'
  ];
  static const _englishTabs = <String>[
    'Overview', 'Brand Designer', 'Match Calculator',
    'Library', 'My Designs', 'History',
  ];
  String tabLabel(int index) =>
    FittedLocaleScope.languageOf(context)=='en'
      ?_englishTabs[index]:_tabs[index];

  static const _icons = <IconData>[
    Icons.space_dashboard_outlined,
    Icons.palette_outlined,
    Icons.tune_outlined,
    Icons.collections_outlined,
    Icons.layers_outlined,
    Icons.history_outlined
  ];
  static const _paletteSeeds = <Map<String, String>>[
    {'name':'Fitted · Pizarra y Plata','primary':'#DDE7EC','accent':'#8196A2','background':'#1A2D38'},
    {'name':'Fitted · Pizarra y Menta','primary':'#8EF0D5','accent':'#68D4C7','background':'#1A2D38'},
    {'name':'Fitted Motion · Midnight Aurora','primary':'#D9C3FF','accent':'#65D3FA','background':'#0D1030'},
    {'name':'Bosque', 'primary':'#D5BE8A','accent':'#9FB5A9','background':'#101B21'},
    {'name':'Azul noche', 'primary':'#152D3D','accent':'#859EA3','background':'#F4F5F2'},
    {'name':'Tierra', 'primary':'#5A4838','accent':'#B2936A','background':'#FAF5EB'},
    {'name':'Pizarra', 'primary':'#36434A','accent':'#8D9A9D','background':'#F4F5F4'},
    {'name':'Salvia', 'primary':'#455D4B','accent':'#9AA57D','background':'#F8F7F1'},
  ];

  final name = TextEditingController(text:'Fitted');
  final tagline = TextEditingController(text:'Conexiones con intención.');
  final headline = TextEditingController(text:'Personas afines a tu forma de vivir.');
  final description = TextEditingController(
    text:'Una comunidad para personas que valoran la vida activa y las relaciones serias.');
  final paletteName = TextEditingController(text:'Fitted · Pizarra y Menta');
  final primary = TextEditingController(text:'#8EF0D5');
  final accent = TextEditingController(text:'#68D4C7');
  final background = TextEditingController(text:'#1A2D38');
  final draftTitle = TextEditingController(text:'Propuesta elegante 40+');
  int tab = 0;
  int logoIndex = 0;
  String? selectedLogoAsset;
  String font = 'Arial';
  String license = 'open';
  String selectedUploadKind = 'logo';
  String layout = 'editorial';
  bool dark = false;
  bool mobilePreview = false;
  bool busy = false;
  bool loading = true;
  String? error;
  bool _brandReady=false;
  bool _brandHydrating=true;
  bool _brandSaving=false;
  bool _brandDirty=false;
  int _brandHydratedVersion=-1;
  String? brandStatus;
  List<Map<String,dynamic>> brandHistory=[];
  Map<String, dynamic>? draft;
  List<Map<String, dynamic>> palettes = [];
  List<Map<String, dynamic>> assets = [];
  List<Map<String, dynamic>> drafts = [];
  List<Map<String, dynamic>> revisions = [];
  final Map<String, String> selectedImages = {};
  final Map<String, Uint8List> downloaded = {};

  @override
  void initState() {
    super.initState();
    for (final c in [name,tagline,headline,description,
      paletteName,primary,accent,background]) {
      c.addListener(_redraw);
    }
    widget.liveBrand.addListener(_observeBrand);
    if(widget.liveBrand.loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_){
        if(mounted)_hydrateLiveBrand();
      });
    } else {
      unawaited(widget.liveBrand.refresh());
    }
    _reload();
  }

  void _redraw() {
    if(mounted)setState(() {});
    if(!_brandHydrating)_markPreviewDirty();
  }

  @override
  void dispose() {
    widget.liveBrand.removeListener(_observeBrand);
    for (final c in [name,tagline,headline,description,paletteName,
      primary,accent,background,draftTitle]) {
      c.dispose();
    }
    super.dispose();
  }

  void _notice(String text, {bool bad=false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: FittedText(text),
      backgroundColor: bad ? const Color(0xFF8F3434) : null,
    ));
  }

  Future<void> _reload() async {
    if (mounted) setState(() {loading=true;error=null;});
    try {
      final result = await Future.wait([
        widget.repository.loadPalettes(),
        widget.repository.loadAssets(),
        widget.repository.loadDrafts(),
      ]);
      if (mounted) setState(() {
        palettes=result[0]; assets=result[1]; drafts=result[2];loading=false;
      });
    } catch (_) {
      if (mounted) setState(() {
        loading=false;error='No pudimos validar las opciones de marca. '
          'Comprueba tu sesión MFA e inténtalo de nuevo.';
      });
    }
  }

  Color _color(String value, Color fallback) {
    if (!BrandAdminRepository.validHex(value)) return fallback;
    return Color(int.parse(value.substring(1), radix:16)|0xFF000000);
  }

  Map<String, String> get colors => {
    'primary': primary.text.trim(),
    'accent': accent.text.trim(),
    'background': background.text.trim(),
  };
  bool get validPalette => colors.values.every(BrandAdminRepository.validHex);

  void _applyPalette(Map<String, String> data) {
    setState(() {
      paletteName.text=data['name'] ?? 'Personalizada';
      primary.text=data['primary'] ?? '#28463D';
      accent.text=data['accent'] ?? '#B49A6A';
      background.text=data['background'] ?? '#F7F5F0';
    });
  }

  String get _selectedPaletteKey {
    bool matches(Map<String, String> p) =>
      paletteName.text.trim()==p['name'] &&
      primary.text.trim().toUpperCase()==p['primary']?.toUpperCase() &&
      accent.text.trim().toUpperCase()==p['accent']?.toUpperCase() &&
      background.text.trim().toUpperCase()==p['background']?.toUpperCase();
    for(var i=0;i<_paletteSeeds.length;i++){
      if(matches(_paletteSeeds[i]))return 'seed:$i';
    }
    for(final item in palettes){
      final raw=Map<String,dynamic>.from(item['colors'] as Map);
      final data=<String,String>{
        'name':item['name'].toString(),
        for(final key in ['primary','accent','background'])
          key:raw[key]?.toString()??'',
      };
      if(matches(data))return 'saved:${item['id']}';
    }
    return 'custom';
  }

  void _choosePalette(String? selected) {
    if(selected==null||selected=='custom')return;
    if(selected.startsWith('seed:')){
      final index=int.tryParse(selected.substring(5));
      if(index!=null&&index>=0&&index<_paletteSeeds.length){
        _applyPalette(_paletteSeeds[index]);
      }
    }else if(selected.startsWith('saved:')){
      final id=selected.substring(6);
      for(final item in palettes){
        if(item['id'].toString()!=id)continue;
        final c=Map<String,dynamic>.from(item['colors'] as Map);
        _applyPalette({
          'name':item['name'].toString(),
          for(final k in ['primary','accent','background'])
            k:c[k].toString(),
        });
        break;
      }
    }
  }

  Future<void> _chooseColor(TextEditingController controller,String label) async {
    final result=await FittedColorPicker.show(context,
      label:label,initialColor:_color(controller.text,Colors.white));
    if(result==null||!mounted)return;
    final value='#${(result.toARGB32()&0xFFFFFF).toRadixString(16).padLeft(6,'0').toUpperCase()}';
    setState(()=>controller.text=value);
  }

  Widget _colorSelector(String label,TextEditingController controller){
    final c=_color(controller.text,Colors.white);
    final border=Theme.of(context).colorScheme.outline;
    return Padding(
      padding:const EdgeInsets.only(bottom:9),
      child:OutlinedButton(
        key:Key('brand-color-${label.toLowerCase()}'),
        onPressed:()=>_chooseColor(controller,label),
        style:OutlinedButton.styleFrom(
          padding:const EdgeInsets.symmetric(horizontal:13,vertical:12)),
        child:Row(children:[
          Container(width:38,height:38,
            decoration:BoxDecoration(
              color:c,borderRadius:BorderRadius.circular(10),
              border:Border.all(color:border))),
          const SizedBox(width:13),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              Text(label,style:Theme.of(context).textTheme.bodyLarge),
              Text(controller.text.toUpperCase(),
                style:Theme.of(context).textTheme.bodySmall),
            ])),
          const Icon(Icons.colorize_outlined,size:20),
          const SizedBox(width:5),
          const Icon(Icons.chevron_right,size:18),
        ]),
      ),
    );
  }

  Future<void> _deleteSelectedPalette() async {
    final selected=_selectedPaletteKey;
    if(!selected.startsWith('saved:'))return;
    final remove=await showDialog<bool>(context:context,
      builder:(context)=>AlertDialog(
        title:const Text('Eliminar paleta guardada'),
        content:Text('¿Eliminar «${paletteName.text}» del catálogo? '
          'Los colores publicados no cambiarán hasta que elijas otra paleta.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context,false),
            child:const Text('Cancelar')),
          FilledButton(onPressed:()=>Navigator.pop(context,true),
            child:const Text('Eliminar')),
        ]));
    if(remove!=true||!mounted)return;
    try{
      await widget.repository.deletePalette(selected.substring(6));
      if(!mounted)return;
      paletteName.text='Personalizada';
      await _reload();
      _notice('Paleta eliminada del catálogo. Los colores continúan disponibles.');
    }catch(_){
      _notice('No fue posible eliminar esta paleta. Verifica tu sesión MFA.',bad:true);
    }
  }

  Widget _logoGlyph(int index,double size,Color p,Color a)=>
    index==0?FittedMintMark(size:size):FittedLogoGlyph(
      index:index,size:size,primary:p,accent:a);

  Future<void> _inspectLogo(int index) async {
    final p=_color(primary.text,const Color(0xFFDDE7EC));
    final a=_color(accent.text,const Color(0xFF8196A2));
    final selected=await showDialog<bool>(
      context:context,
      builder:(context)=>AlertDialog(
        key:const Key('brand-logo-detail'),
        title:Text(FittedLogoCatalog.names[index]),
        content:ConstrainedBox(
          constraints:const BoxConstraints(maxWidth:320),
          child:Column(mainAxisSize:MainAxisSize.min,children:[
            Container(
              width:180,height:180,
              padding:const EdgeInsets.all(18),
              decoration:BoxDecoration(
                color:Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius:BorderRadius.circular(26)),
              child:_logoGlyph(index,144,p,a)),
            const SizedBox(height:15),
            Text(FittedLogoCatalog.descriptions[index],
              textAlign:TextAlign.center),
            const SizedBox(height:8),
            Text('Vector escalable · sin archivos externos',
              textAlign:TextAlign.center,
              style:Theme.of(context).textTheme.bodySmall),
          ])),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context,false),
            child:const Text('Cerrar')),
          FilledButton(
            key:const Key('brand-logo-apply'),
            onPressed:()=>Navigator.pop(context,true),
            child:const Text('Usar este logotipo')),
        ],
      ));
    if(selected==true&&mounted){
      setState((){
        selectedLogoAsset=null;
        logoIndex=index;
      });
      _markPreviewDirty();
    }
  }

  Future<void> _savePalette() async {
    if(palettes.length>=BrandAdminRepository.maxSavedPalettes){
      _notice('Alcanzaste 50 paletas guardadas. Elimina alguna para crear otra.',
        bad:true);
      return;
    }
    try {
      await widget.repository.createPalette(paletteName.text, colors);
      await _reload();
      _notice('Paleta incorporada al catálogo administrativo.');
    } catch (e) {
      _notice('No se guardó la paleta. Comprueba el nombre, el límite y MFA.',
        bad:true);
    }
  }



  // The editable controls are a local sandbox. No change is pushed until
  // Save & publish is tapped. Remote updates never overwrite unsaved edits.
  void _observeBrand(){
    if(!mounted||!widget.liveBrand.loaded)return;
    if(!_brandReady){_hydrateLiveBrand();return;}
    if(_brandSaving)return;
    if(widget.liveBrand.version>_brandHydratedVersion){
      if(_brandDirty){
        setState(()=>brandStatus='Otra sesión publicó una versión nueva. '
          'Tus pruebas están intactas; descarta para cargar esa versión.');
      }else{_hydrateLiveBrand();}
    }
  }

  void _hydrateLiveBrand(){
    if(!mounted)return;
    _brandHydrating=true;
    final settings=widget.liveBrand.current;
    setState((){
      name.text=settings.name;
      tagline.text=settings.tagline;
      headline.text=settings.title;
      description.text=settings.description;
      paletteName.text=settings.paletteName;
      primary.text=settings.primary;
      accent.text=settings.accent;
      background.text=settings.background;
      font=settings.font;
      dark=settings.dark;
      layout=settings.layout;
      if(settings.logo.startsWith('catalog:')){
        logoIndex=(int.tryParse(settings.logo.substring(8))??0).clamp(0,20);
        selectedLogoAsset=null;
      }else{selectedLogoAsset=settings.logo;}
      selectedImages..clear()..addAll(settings.media);
      _brandHydratedVersion=widget.liveBrand.version;
      _brandReady=true;
      _brandDirty=false;
      brandStatus='Versión publicada ${widget.liveBrand.version} · '
        'Seleccionar opciones sólo modifica la vista previa';
    });
    _brandHydrating=false;
  }

  void _markPreviewDirty(){
    if(!_brandReady||_brandHydrating||!mounted)return;
    if(!_brandDirty){
      setState((){
        _brandDirty=true;
        brandStatus='Cambios sin publicar · Sólo visibles en la vista previa';
      });
    }
  }

  Future<void> _discardPreviewChanges()async{
    if(!_brandDirty){_hydrateLiveBrand();return;}
    final yes=await showDialog<bool>(context:context,
      builder:(ctx)=>AlertDialog(
        title:const Text('Descartar cambios de prueba'),
        content:const Text('Regresarás a la identidad publicada. '
          'Los cambios sin guardar se perderán.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:const Text('Seguir editando')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:const Text('Descartar cambios')),
        ]));
    if(yes==true&&mounted){
      _hydrateLiveBrand();
      draft=null;
    }
  }

  Future<void> _saveBrandGlobally()async{
    if(!_brandReady||!mounted||_brandSaving)return;
    if(_brandHydratedVersion!=widget.liveBrand.version){
      setState(()=>brandStatus='Otra sesión publicó cambios. '
        'Descarta la vista previa para obtener la nueva versión antes de guardar.');
      return;
    }
    final pending=_settings();
    final selectedLogo=pending['logo'].toString();
    if(!validPalette ||
       name.text.trim().length<2 || name.text.trim().length>60 ||
       tagline.text.trim().length<2 || tagline.text.trim().length>120 ||
       headline.text.trim().length<8 || headline.text.trim().length>180 ||
       description.text.trim().length<10 || description.text.trim().length>600 ||
       paletteName.text.trim().length<2 ||
       !FittedFontCatalog.accepts(font) ||
       (selectedLogoAsset!=null &&
         !LiveBrandSettings.safeAssetUrl(selectedLogoAsset!)) ||
       (selectedLogo.startsWith('https://') &&
         !LiveBrandSettings.safeAssetUrl(selectedLogo)) ||
       selectedImages.values.any((v)=>!LiveBrandSettings.safeAssetUrl(v))){
      setState(()=>brandStatus='Revisa nombre, colores, fuente y archivos. '
        'No se publicó ningún cambio.');
      return;
    }
    final snapshot=const JsonEncoder().convert(pending);
    final proposed=LiveBrandSettings.fromMap(pending);
    if(widget.liveBrand.asJson==const JsonEncoder().convert(proposed.toMap())){
      setState((){
        _brandDirty=false;
        brandStatus='Ya es la versión publicada · ${widget.liveBrand.version}';
      });
      return;
    }
    _brandSaving=true;
    setState(()=>brandStatus='Guardando y publicando en toda Fitted…');
    try{
      await widget.liveBrand.save(proposed);
      if(!mounted)return;
      _brandHydratedVersion=widget.liveBrand.version;
      final continued=const JsonEncoder().convert(_settings())!=snapshot;
      setState((){
        _brandDirty=continued;
        brandStatus=continued
          ?'Versión ${widget.liveBrand.version} publicada. '
            'Aún tienes pruebas sin publicar.'
          :'Guardado y publicado para todos · versión ${widget.liveBrand.version}';
      });
      if(!continued)_notice('Cambios publicados correctamente en toda Fitted.');
    }catch(_){
      if(mounted)setState((){
        _brandDirty=true;
        brandStatus='No se publicó. Tu vista previa sigue intacta. '
          'Verifica MFA, conexión o conflictos con otra sesión.';
      });
    }finally{_brandSaving=false;}
  }

  Future<void> _fetchBrandHistory() async {
    try {
      final versions=await widget.liveBrand.history();
      if(mounted)setState(()=>brandHistory=versions);
    } catch (_) {
      _notice('No se pudo consultar el historial de marca.',bad:true);
    }
  }

  Future<void> _restoreBrandVersion(int version) async {
    if(_brandSaving)return;
    try {
      await widget.liveBrand.restore(version);
      _hydrateLiveBrand();
      await _fetchBrandHistory();
      _notice('Versión restaurada. El cambio es visible en toda la app.');
    } catch (_) {
      _notice('No se pudo restaurar. Comprueba tu sesión MFA.',bad:true);
    }
  }

  Map<String, dynamic> _settings() => {
    'name':name.text.trim(),
    'tagline':tagline.text.trim(),
    'title':headline.text.trim(),
    'description':description.text.trim(),
    'paletteName':paletteName.text.trim(),
    'colors':colors,
    'font':font,
    'logo':selectedLogoAsset!=null &&
        LiveBrandSettings.safeAssetUrl(selectedLogoAsset!)
      ? selectedLogoAsset! : 'catalog:$logoIndex',
    'media':{
      for(final item in selectedImages.entries)
        if(const ['cover_desktop','cover_mobile','app_image'].contains(item.key)
          && LiveBrandSettings.safeAssetUrl(item.value))
          item.key:item.value,
    },
    'layout':layout,
    'mode':dark ? 'dark' : 'light',
  };

  Future<void> _saveDraft() async {
    if (!validPalette || name.text.trim().isEmpty) {
      _notice('Revisa el nombre y los colores HEX de la identidad.',bad:true);
      return;
    }
    setState(()=>busy=true);
    try {
      final updated = await widget.repository.saveDraft(
        title:draftTitle.text,
        settings:_settings(),
        prior:draft,
      );
      draft=updated;
      await _reload();
      _notice('Borrador guardado en Supabase · revisión ${updated['revision']}. '
        'No modifica la marca pública.');
    } catch (_) {
      _notice('No fue posible guardar. Recarga si otro administrador cambió la versión.',bad:true);
    } finally {
      if (mounted) setState(()=>busy=false);
    }
  }

  Future<void> _loadDraft(Map<String, dynamic> item) async {
    try {
      final settings=Map<String,dynamic>.from(item['settings'] as Map);
      final c=Map<String,dynamic>.from(settings['colors'] as Map);
      if (!c.values.every((x)=>x is String &&
          BrandAdminRepository.validHex(x))) {
        throw const FormatException('invalid colors');
      }
      setState(() {
        draft=item;
        draftTitle.text=(item['title']??'Borrador').toString();
        name.text=(settings['name']??'Fitted').toString();
        tagline.text=(settings['tagline']??'').toString();
        headline.text=(settings['title']??'').toString();
        description.text=(settings['description']??'').toString();
        paletteName.text=(settings['paletteName']??'Personalizada').toString();
        primary.text=c['primary'].toString();
        accent.text=c['accent'].toString();
        background.text=c['background'].toString();
        font=(settings['font']??'Georgia').toString();
        final logo=(settings['logo']??'catalog:0').toString();
        selectedLogoAsset=LiveBrandSettings.safeAssetUrl(logo)?logo:null;
        final parsed=int.tryParse(logo.replaceFirst('catalog:',''));
        logoIndex=(parsed??0).clamp(0,20);
        dark=settings['mode']=='dark';
        layout=(settings['layout']??'editorial').toString();
        selectedImages
          ..clear()
          ..addAll(Map<String,String>.from(settings['media']??{}));
        tab=1;
      });
      _notice('Borrador cargado para edición. No hay cambios publicados.');
    } catch (_) {
      _notice('El borrador contiene datos no compatibles.',bad:true);
    }
  }

  Future<void> _fetchRevisions() async {
    if(draft==null)return;
    try {
      final rows=await widget.repository.loadRevisions(draft!['id'] as String);
      if(mounted)setState(()=>revisions=rows);
    } catch (_) {
      _notice('No fue posible consultar las revisiones.',bad:true);
    }
  }

  Future<void> _upload() async {
    if(busy)return;
    final kind=selectedUploadKind;
    final extensions=kind=='font' ? ['woff2']
      :kind=='logo'||kind=='icon' ? ['png','webp']
      :['jpg','jpeg','png','webp'];
    try {
      final file=await FilePicker.pickFile(
        type:FileType.custom,allowedExtensions:extensions);
      if(file==null)return;
      final bytes=await file.readAsBytes();
      if(!mounted)return;
      setState(()=>busy=true);
      if(const ['logo','cover_desktop','cover_mobile','app_image']
          .contains(kind)) {
        // An explicit owner selection creates an immutable public image
        // in the dedicated bucket. No private draft file is leaked.
        final url=await widget.repository.uploadPublicBrandAsset(
          kind:kind,name:file.name,bytes:bytes);
        downloaded[url]=bytes;
        if(mounted)setState((){
          if(kind=='logo')selectedLogoAsset=url;
          else selectedImages[kind]=url;
        });
        _markPreviewDirty();
        _notice('Imagen seleccionada. Guardando para todos los usuarios.');
      } else {
        final saved=await widget.repository.uploadAsset(
          kind:kind,name:file.name,bytes:bytes,license:license);
        downloaded[saved['id'] as String]=bytes;
        await _reload();
        _notice(kind=='font'
          ?'Fuente conservada en biblioteca. La marca en vivo usa fuentes del catálogo.'
          :'Recurso guardado en biblioteca privada; no se publica automáticamente.');
      }
    } catch (_) {
      _notice('No se pudo subir. Comprueba tipo, tamaño y sesión MFA.',bad:true);
    } finally {
      if(mounted)setState(()=>busy=false);
    }
  }

  Future<void> _loadAsset(Map<String,dynamic> item) async {
    final id=item['id'] as String;
    final kind=item['asset_kind'] as String;
    if(kind=='font') {
      _notice('Las fuentes WOFF2 privadas se prepararán para la fase avanzada.');
      return;
    }
    try {
      setState(()=>busy=true);
      final bytes=downloaded[id] ??
        await widget.repository.loadPrivateAsset(item);
      if(!mounted)return;
      downloaded[id]=bytes;
      if(const ['logo','cover_desktop','cover_mobile','app_image']
          .contains(kind)) {
        // Copy once into the public, owner-checked bucket on selection.
        final url=await widget.repository.uploadPublicBrandAsset(
          kind:kind,name:item['name'].toString(),bytes:bytes);
        downloaded[url]=bytes;
        setState((){
          if(kind=='logo')selectedLogoAsset=url;
          else selectedImages[kind]=url;
        });
        _markPreviewDirty();
      } else {
        _notice('Esta clase de recurso todavía permanece privada.');
      }
    } catch (_) {
      _notice('No fue posible usar este recurso públicamente.',bad:true);
    } finally {
      if(mounted)setState(()=>busy=false);
    }
  }

  Widget _header(String title, String subtitle) => Padding(
    padding:const EdgeInsets.only(bottom:15),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      FittedText(title,style:Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height:7),
      FittedText(subtitle,style:Theme.of(context).textTheme.bodyMedium),
    ]),
  );

  Widget _field(TextEditingController ctrl,String label,{int lines=1}) =>
    Padding(padding:const EdgeInsets.only(bottom:12),
      child:TextField(
        controller:ctrl,maxLines:lines,
        decoration:InputDecoration(labelText:label),
      ));

  Widget _summary() => ListView(padding:const EdgeInsets.all(22),children:[
    _header('Panel de Administración',
      'Tu aplicación. Publica actividades y configura el diseño que verán todos.'),
    Wrap(spacing:12,runSpacing:12,children:[
      _stat('Paletas',palettes.length,Icons.palette_outlined),
      _stat('Recursos privados',assets.length,Icons.image_outlined),
      _stat('Borradores',drafts.length,Icons.layers_outlined),
    ]),
    const SizedBox(height:24),
    Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        FittedText('Brand Studio',style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:8),
        const FittedText('Configura nombre, paletas, textos, logotipos y portadas. '
          'Se guardan globalmente sin revisión ni despliegue adicional.'),
        const SizedBox(height:12),
        FilledButton.icon(
          onPressed:()=>setState(()=>tab=1),
          icon:const Icon(Icons.design_services_outlined),
          label:const FittedText('Editar marca en vivo'),
        ),
      ],
    ))),
    if (widget.curatorApi != null) ...[
      const SizedBox(height:14),
      Card(child:Padding(padding:const EdgeInsets.all(20),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          FittedText('Actividades deportivas',
            style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:8),
          const FittedText('Publica actividades verificadas para los miembros y '
            'mira cómo se ven en la aplicación, sin salir de tu cuenta '
            'administrativa ni solicitar un nuevo despliegue.'),
          const SizedBox(height:12),
          FilledButton.icon(
            key:const Key('b2-admin-open-curation'),
            onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
              builder:(_)=>AdminCuratedActivitiesB2(api:widget.curatorApi!))),
            icon:const Icon(Icons.event_available_outlined),
            label:const FittedText('Administrar actividades')),
          if(widget.activityPreviewApi!=null) ...[
            const SizedBox(height:10),
            OutlinedButton.icon(
              key:const Key('b2-admin-member-preview'),
              onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
                builder:(_)=>ActivitiesB1(
                  api:widget.activityPreviewApi!,readOnly:true))),
              icon:const Icon(Icons.visibility_outlined),
              label:const FittedText('Ver como miembro (solo lectura)')),
          ],
        ]))),
    ],
    const SizedBox(height:14),
    Card(child:Padding(padding:const EdgeInsets.all(20),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        FittedText('Gimnasios para Gym Shield',
          style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:8),
        const FittedText('Catálogo de gimnasios reales para proteger '
          'los lugares y horarios privados de los miembros. '
          'Registro administrativo con MFA y auditoría.'),
        const SizedBox(height:12),
        FilledButton.icon(
          key:const Key('b11-admin-open-gym-catalog'),
          onPressed:()=>Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder:(_)=>GymCatalogueAdminB11(
                repository:widget.repository))),
          icon:const Icon(Icons.fitness_center_outlined),
          label:const FittedText('Administrar gimnasios'),
        ),
      ]))),
    if(widget.communityAdmin is MemberV26Api)...[
      const SizedBox(height:14),
      Card(child:Padding(padding:const EdgeInsets.all(20),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          FittedText('Verificación de edad y operación de citas',
            style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:8),
          const FittedText('Identificación privada, comparación manual de '
            'fotografía, verificación de mayoría de edad, eliminación de '
            'evidencia y controles de lanzamiento con MFA.'),
          const SizedBox(height:12),
          FilledButton.icon(
            key:const Key('admin-open-age-verification-b14'),
            onPressed:()=>Navigator.of(context).push(
              MaterialPageRoute<void>(builder:(_)=>
                FittedAgeAdminB14(
                  api:widget.communityAdmin as MemberV26Api))),
            icon:const Icon(Icons.verified_user_outlined),
            label:const FittedText('Revisar identidades y habilitación')),
        ]))),
    ],
    if(widget.communityAdmin is MemberV26Api)...[
      const SizedBox(height:14),
      Card(child:Padding(padding:const EdgeInsets.all(20),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          FittedText('Pulso Real · confianza y revisión',
            style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:8),
          const FittedText('Revisión humana de la coherencia percibida tras '
            'un encuentro, con apelaciones y auditoría. '
            'Nada se publica como una acusación automática.'),
          const SizedBox(height:12),
          OutlinedButton.icon(
            key:const Key('admin-open-pulse-moderation'),
            onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
              builder:(_)=>FittedPulseModerationB13(
                api:widget.communityAdmin as MemberV26Api))),
            icon:const Icon(Icons.fact_check_outlined),
            label:const FittedText('Revisar señales y apelaciones')),
        ]))),
    ],
    if(widget.communityAdmin!=null)...[
      const SizedBox(height:14),
      Card(child:Padding(padding:const EdgeInsets.all(20),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          FittedText('Seguridad de comunidad',
            style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:8),
          const FittedText('Revisa denuncias, oculta publicaciones, suspende '
            'participaciones y consulta solicitudes de baja con trazabilidad.'),
          const SizedBox(height:12),
          FilledButton.icon(
            key:const Key('b4-admin-open-moderation'),
            onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
              builder:(_)=>CommunityModerationB4(api:widget.communityAdmin!))),
            icon:const Icon(Icons.gpp_good_outlined),
            label:const FittedText('Moderación y privacidad')),
        ]))),
    ],
    const SizedBox(height:14),
    const Card(child:Padding(padding:EdgeInsets.all(18),
      child:FittedText('Los cambios de apariencia internos se guardan sin otro build. '
        'El icono instalado, tiendas y permisos móviles continúan requiriendo publicación de software.'))),
  ]);

  Widget _stat(String label,int value,IconData icon)=>SizedBox(
    width:205,child:Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        Icon(icon,size:30),
        const SizedBox(height:14),
        FittedText('$value',style:Theme.of(context).textTheme.headlineMedium),
        FittedText(label),
      ],
    ))));

  Widget _editor() => ListView(padding:const EdgeInsets.all(18),children:[
    _header('Marca global en vivo',
      'Los cambios se muestran aquí y se guardan automáticamente para todas las personas.'),
    if(!_brandReady) const LinearProgressIndicator(),
    if(brandStatus!=null) Padding(
      padding:const EdgeInsets.only(bottom:12),
      child:Row(children:[
        Icon(_brandSaving?Icons.sync:Icons.cloud_done_outlined,size:20),
        const SizedBox(width:8),
        Expanded(child:FittedText(brandStatus!,key:const Key('b3-save-status'))),
        if(!_brandReady) TextButton(onPressed:()=>widget.liveBrand.refresh(),
          child:const FittedText('Sincronizar')),
      ])),
    LayoutBuilder(builder:(context,box) {
      final wide=box.maxWidth>=950;
      final editor=_identityControls();
      final preview=_preview();
      return wide?Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Expanded(flex:5,child:editor),const SizedBox(width:14),
        Expanded(flex:4,child:preview),
      ]):Column(children:[editor,const SizedBox(height:14),preview]);
    }),
  ]);

  Widget _identityControls()=>Column(
    crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          FittedText('Nombre y comunicación',style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:12),
          _field(name,'Nombre de la aplicación'),
          _field(tagline,'Lema'),
          _field(headline,'Título de portada'),
          _field(description,'Presentación',lines:3),
        ]))),
      const SizedBox(height:10),
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          FittedText('Paletas y colores',
            style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:7),
          Text('Elige una combinación o crea hasta 50 paletas propias.',
            style:Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height:12),
          KeyedSubtree(
            key:const Key('brand-palette-selector'),
            child:DropdownButtonFormField<String>(
              key:ValueKey('palette-${_selectedPaletteKey}'),
              isExpanded:true,
              menuMaxHeight:340,
              initialValue:_selectedPaletteKey,
              decoration:const InputDecoration(
                labelText:'Selecciona una paleta',
                prefixIcon:Icon(Icons.palette_outlined)),
              items:[
                const DropdownMenuItem(
                  value:'custom',child:Text('Personalizada · edición actual')),
                for(var i=0;i<_paletteSeeds.length;i++)
                  DropdownMenuItem(
                    value:'seed:$i',
                    child:Text(_paletteSeeds[i]['name']!,
                      maxLines:1,overflow:TextOverflow.ellipsis)),
                for(final item in palettes)
                  DropdownMenuItem(
                    value:'saved:${item['id']}',
                    child:Text('★ ${item['name']}',
                      maxLines:1,overflow:TextOverflow.ellipsis)),
              ],
              onChanged:_choosePalette,
            ),
          ),
          const SizedBox(height:12),
          Wrap(spacing:5,runSpacing:7,children:[
            for(final item in [
              (name:'Primario',c:primary.text),
              (name:'Acento',c:accent.text),
              (name:'Fondo',c:background.text),
            ])
              Chip(label:Text(item.name),
                avatar:CircleAvatar(
                  backgroundColor:_color(item.c,Colors.white),radius:10)),
          ]),
          const SizedBox(height:12),
          _colorSelector('Primario',primary),
          _colorSelector('Acento',accent),
          _colorSelector('Fondo',background),
          const SizedBox(height:9),
          Text('Mis paletas guardadas: ${palettes.length} de 50',
            key:const Key('brand-palette-count'),
            style:Theme.of(context).textTheme.bodySmall),
          const SizedBox(height:9),
          _field(paletteName,'Nombre de la combinación'),
          Wrap(spacing:10,runSpacing:7,children:[
            FilledButton.tonalIcon(
              key:const Key('brand-palette-save'),
              onPressed:validPalette&&
                palettes.length<BrandAdminRepository.maxSavedPalettes
                  ?_savePalette:null,
              icon:const Icon(Icons.add_circle_outline),
              label:const FittedText('Guardar como paleta')),
            if(_selectedPaletteKey.startsWith('saved:'))
              OutlinedButton.icon(
                key:const Key('brand-palette-delete'),
                onPressed:_deleteSelectedPalette,
                icon:const Icon(Icons.delete_outline),
                label:const Text('Eliminar guardada')),
          ]),
        ]))),
      const SizedBox(height:10),
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          FittedText('Tipografía',style:Theme.of(context).textTheme.titleLarge),
          DropdownButtonFormField<String>(
            key:ValueKey('font-$font'),initialValue:font,
            decoration:InputDecoration(labelText:FittedLocaleScope.translate(context,'Familia de prueba')),
            items:[
              for(final f in ['Georgia','Palatino','Garamond','Arial'])
                DropdownMenuItem(value:f,child:FittedText(f)),
              if(font.startsWith('asset:'))
                DropdownMenuItem(value:font,
                  child:const FittedText('Fuente WOFF2 cargada (requiere compilación)')),
            ],
            onChanged:(v){setState(()=>font=v??'Georgia');_markPreviewDirty();},
          ),
          const SizedBox(height:8),
          const FittedText('Las fuentes WOFF2 se conservan en la biblioteca. '
            'Su visualización nativa completa requiere procesarlas para Flutter.',
            style:TextStyle(fontSize:12)),
        ]))),
      const SizedBox(height:10),
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          FittedText('Galería de logotipos',
            style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:7),
          Text('20 símbolos vectoriales originales, además del monograma '
            'actual. Selecciona una miniatura para verla ampliada.',
            style:Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height:12),
          SizedBox(height:130,
            child:ListView.separated(
              key:const Key('brand-logo-reel'),
              scrollDirection:Axis.horizontal,
              itemCount:FittedLogoCatalog.count,
              separatorBuilder:(_,__)=>const SizedBox(width:10),
              itemBuilder:(context,i){
                final chosen=selectedLogoAsset==null&&logoIndex==i;
                final p=_color(primary.text,const Color(0xFFDDE7EC));
                final a=_color(accent.text,const Color(0xFF8196A2));
                return Material(
                  color:chosen?Theme.of(context).colorScheme.primary
                    .withValues(alpha:.11):
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius:BorderRadius.circular(16),
                  child:InkWell(
                    key:Key('admin-logo-$i'),
                    borderRadius:BorderRadius.circular(16),
                    onTap:()=>_inspectLogo(i),
                    child:Container(
                      width:105,padding:const EdgeInsets.all(9),
                      decoration:BoxDecoration(
                        border:Border.all(
                          color:chosen?Theme.of(context).colorScheme.primary:
                            Theme.of(context).colorScheme.outline
                              .withValues(alpha:.38),
                          width:chosen?2:1),
                        borderRadius:BorderRadius.circular(16)),
                      child:Column(mainAxisAlignment:MainAxisAlignment.center,
                        children:[
                          _logoGlyph(i,69,p,a),
                          const SizedBox(height:7),
                          Text(FittedLogoCatalog.names[i],
                            maxLines:1,overflow:TextOverflow.ellipsis,
                            style:Theme.of(context).textTheme.labelMedium),
                        ]),
                    ),
                  ),
                );
              },
            )),
          const SizedBox(height:11),
          Row(children:[
            const Icon(Icons.touch_app_outlined,size:17),
            const SizedBox(width:8),
            const Expanded(child:Text(
              'Desliza para explorar; toca para ampliar y aplicar.')),
          ]),
          const SizedBox(height:14),
          OutlinedButton.icon(
            key:const Key('brand-logo-upload-own'),
            onPressed:busy?null:()async{
              selectedUploadKind='logo';
              await _upload();
            },
            icon:const Icon(Icons.upload_file_outlined),
            label:const Text('Subir mi propio logotipo · PNG o WebP')),
          if(selectedLogoAsset!=null) ...[
            const SizedBox(height:9),
            Text('Logotipo personalizado seleccionado',
              style:Theme.of(context).textTheme.bodySmall),
            TextButton.icon(
              onPressed:(){
                setState(()=>selectedLogoAsset=null);
                _markPreviewDirty();
              },
              icon:const Icon(Icons.restore_outlined),
              label:const Text('Volver al catálogo')),
          ],
          const SizedBox(height:10),
          SwitchListTile(
            title:const FittedText('Vista oscura'),
            value:dark,
            onChanged:(v){setState(()=>dark=v);_markPreviewDirty();}),
          DropdownButtonFormField<String>(
            key:ValueKey('layout-$layout'),
            initialValue:layout,
            items:const [
              DropdownMenuItem(value:'editorial',child:FittedText('Editorial')),
              DropdownMenuItem(value:'minimal',child:FittedText('Minimalista')),
            ],
            onChanged:(v){setState(()=>layout=v??'editorial');_markPreviewDirty();},
            decoration:InputDecoration(labelText:FittedLocaleScope.translate(context,'Distribución')),
          ),
        ]))),
      const SizedBox(height:12),
      const ListTile(
        key:Key('b3-auto-publish-label'),
        leading:Icon(Icons.cloud_done_outlined),
        title:FittedText('Guardado automático activo'),
        subtitle:FittedText('No hay solicitudes de revisión ni builds por cada cambio.')),
    ]);

  Widget _preview(){
    final p=_color(primary.text,const Color(0xFF28463D));
    final a=_color(accent.text,const Color(0xFFB49A6A));
    final bg=_color(background.text,const Color(0xFFF7F5F0));
    final foreground=bg.computeLuminance()<.35?Colors.white:const Color(0xFF172731);
    final bodyColor=bg;
    final heroAssetId=selectedImages[mobilePreview?'cover_mobile':'cover_desktop'];
    final heroBytes=heroAssetId==null?null:downloaded[heroAssetId];
    final logoBytes=selectedLogoAsset==null?null:downloaded[selectedLogoAsset];
    final ImageProvider? heroProvider=heroBytes!=null
      ? MemoryImage(heroBytes)
      : heroAssetId!=null && LiveBrandSettings.safeAssetUrl(heroAssetId)
        ? NetworkImage(heroAssetId) : null;
    return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(
      crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        FittedText('Vista previa en vivo',style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:8),
        Wrap(children:[
          FilterChip(label:const FittedText('Web'),selected:!mobilePreview,
            onSelected:(_)=>setState(()=>mobilePreview=false)),
          const SizedBox(width:8),
          FilterChip(label:const FittedText('Móvil'),selected:mobilePreview,
            onSelected:(_)=>setState(()=>mobilePreview=true)),
        ]),
        const SizedBox(height:10),
        Align(alignment:Alignment.center,child:ConstrainedBox(
          constraints:BoxConstraints(maxWidth:mobilePreview?340:700),
          child:Container(
            decoration:BoxDecoration(color:bodyColor,
              borderRadius:BorderRadius.circular(mobilePreview?25:13)),
            clipBehavior:Clip.antiAlias,
            child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              Container(padding:const EdgeInsets.all(14),
                color:Color.lerp(bg,dark?Colors.white:Colors.black,.08),
                child:Row(children:[
                  if(logoBytes!=null)
                    Image.memory(logoBytes,width:35,height:35)
                  else if(selectedLogoAsset!=null &&
                    LiveBrandSettings.safeAssetUrl(selectedLogoAsset!))
                    Image.network(selectedLogoAsset!,width:35,height:35)
                  else if(logoIndex==0)
                    const FittedMintMark(size:35)
                  else
                    _logoGlyph(logoIndex,35,p,a),
                  const SizedBox(width:8),
                  Expanded(child:FittedText(name.text.isEmpty?'Mi marca':name.text,
                    maxLines:2,overflow:TextOverflow.ellipsis,
                    style:TextStyle(color:foreground,fontSize:19,
                      fontWeight:FontWeight.w600,
                      fontFamily:font.startsWith('asset:')?null:font))),
                ])),
              Stack(children:[
                Container(
                  constraints:const BoxConstraints(minHeight:280),
                  decoration:BoxDecoration(
                    gradient:LinearGradient(colors:[
                      Color.lerp(bg,p,.15)!,Color.lerp(bg,a,.09)!]),
                    image:heroProvider==null?null:DecorationImage(
                      image:heroProvider,fit:BoxFit.cover,
                      colorFilter:ColorFilter.mode(
                        bg.withValues(alpha:.12),BlendMode.darken))),
                ),
                Padding(padding:const EdgeInsets.all(26),
                  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    FittedText('CONEXIONES CON INTENCIÓN',style:TextStyle(
                      fontSize:11,color:foreground.withValues(alpha:.7),letterSpacing:2)),
                    const SizedBox(height:15),
                    FittedText(headline.text,
                      style:TextStyle(fontFamily:font.startsWith('asset:')?null:font,
                        fontSize:mobilePreview?28:34,
                        color:foreground,height:1.22)),
                    const SizedBox(height:16),
                    FittedText(description.text,style:TextStyle(
                      color:foreground,fontSize:15,height:1.5)),
                    const SizedBox(height:18),
                    Container(
                      decoration:BoxDecoration(
                        color:a,borderRadius:BorderRadius.circular(10)),
                      padding:const EdgeInsets.all(12),
                      child:FittedText('Conocer nuestra propuesta',
                        style:TextStyle(color:a.computeLuminance()>.4
                          ?Colors.black87:Colors.white,fontWeight:FontWeight.w700))),
                  ])),
              ]),
              Container(
                padding:const EdgeInsets.all(20),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  FittedText(tagline.text,style:TextStyle(
                    color:foreground,fontWeight:FontWeight.bold,fontSize:18)),
                  const SizedBox(height:7),
                  FittedText('Cómo me muevo · Cómo vivo · Cómo me relaciono',
                    style:TextStyle(color:foreground)),
                ]),
              ),
            ]),
          ),
        )),
        const SizedBox(height:12),
        FittedText('El diseño de la portada ya usa esta marca global. '
          'Versión activa: ${widget.liveBrand.version}.',
          style:const TextStyle(fontSize:12)),
      ])));
  }

  Widget _library()=>ListView(padding:const EdgeInsets.all(22),children:[
    _header('Biblioteca de marca',
      'Sube logos, portadas, imágenes y tipografías. Todos los originales quedan privados.'),
    Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        DropdownButtonFormField<String>(
          key:ValueKey('asset-kind-$selectedUploadKind'),
          initialValue:selectedUploadKind,
          decoration:InputDecoration(labelText:FittedLocaleScope.translate(context,'Tipo de recurso')),
          items:const [
            DropdownMenuItem(value:'logo',child:FittedText('Logo PNG o WebP')),
            DropdownMenuItem(value:'font',child:FittedText('Tipografía WOFF2')),
            DropdownMenuItem(value:'cover_desktop',child:FittedText('Portada escritorio')),
            DropdownMenuItem(value:'cover_mobile',child:FittedText('Portada móvil')),
            DropdownMenuItem(value:'login_image',child:FittedText('Imagen de acceso')),
            DropdownMenuItem(value:'onboarding_image',child:FittedText('Imagen de onboarding')),
            DropdownMenuItem(value:'app_image',child:FittedText('Imagen interior')),
            DropdownMenuItem(value:'illustration',child:FittedText('Ilustración')),
          ],
          onChanged:(v)=>setState(()=>selectedUploadKind=v??'logo'),
        ),
        if(selectedUploadKind=='font') ...[
          const SizedBox(height:12),
          DropdownButtonFormField<String>(
            initialValue:license,
            decoration:InputDecoration(labelText:FittedLocaleScope.translate(context,'Licencia de uso declarada')),
            items:const [
              DropdownMenuItem(value:'open',child:FittedText('Licencia abierta compatible')),
              DropdownMenuItem(value:'owned',child:FittedText('Soy titular de los derechos')),
              DropdownMenuItem(value:'licensed',child:FittedText('Licencia comercial válida')),
            ],
            onChanged:(v)=>setState(()=>license=v??'open'),
          ),
        ],
        const SizedBox(height:14),
        FilledButton.icon(
          key:const Key('admin-upload-brand-asset'),
          onPressed:busy?null:_upload,
          icon:const Icon(Icons.upload_file_outlined),
          label:FittedText(busy?'Cargando...':'Seleccionar y subir archivo privado'),
        ),
        const SizedBox(height:8),
        const FittedText('Imágenes PNG/WebP/JPG hasta 8 MiB; fuentes WOFF2 hasta '
          '2 MiB. No se admiten SVG externos activos.',style:TextStyle(fontSize:12)),
      ],
    ))),
    const SizedBox(height:16),
    for(final item in assets)
      Card(child:ListTile(
        leading:Icon(item['asset_kind']=='font'?Icons.text_fields:
          item['asset_kind']=='logo'?Icons.auto_awesome_mosaic:Icons.image_outlined),
        title:FittedText(item['name'].toString(),maxLines:1,overflow:TextOverflow.ellipsis),
        subtitle:FittedText('${item['asset_kind']} · ${((item['bytes'] as num)/1024).ceil()} KB'),
        trailing:const Icon(Icons.check_circle_outline),
        onTap:()async{
          await _loadAsset(item);
          if(mounted)setState(()=>tab=1);
          _notice('Recurso seleccionado para el borrador, no para producción.');
        },
      )),
    if(assets.isEmpty)const Padding(
      padding:EdgeInsets.all(20),
      child:FittedText('Aún no hay recursos privados.')),
  ]);

  Widget _drafts()=>ListView(padding:const EdgeInsets.all(22),children:[
    _header('Borradores y versiones',
      'Guarda, consulta y recupera configuraciones. Ninguna cambia la marca pública.'),
    _field(draftTitle,'Título del borrador'),
    FilledButton.icon(
      onPressed:busy?null:_saveDraft,
      icon:const Icon(Icons.save_outlined),
      label:FittedText(draft==null?'Crear borrador':'Guardar nueva revisión'),
    ),
    const SizedBox(height:12),
    OutlinedButton(
      onPressed:()=>setState((){
        draft=null;revisions=[];draftTitle.text='Nueva propuesta';
      }),
      child:const FittedText('Comenzar una propuesta nueva'),
    ),
    if(draft!=null) ...[
      const SizedBox(height:14),
      OutlinedButton.icon(onPressed:_fetchRevisions,
        icon:const Icon(Icons.history),
        label:const FittedText('Ver historial del borrador')),
      for(final rev in revisions)
        ListTile(
          leading:const Icon(Icons.history_toggle_off),
          title:FittedText('Revisión ${rev['revision']}'),
          subtitle:FittedText(rev['recorded_at'].toString()),
        ),
    ],
    const SizedBox(height:20),
    FittedText('Diseños guardados',style:Theme.of(context).textTheme.titleLarge),
    for(final item in drafts)
      Card(child:ListTile(
        title:FittedText(item['title'].toString()),
        subtitle:FittedText('Revisión ${item['revision']} · ${item['updated_at']}'),
        trailing:const Icon(Icons.edit_outlined),
        onTap:()=>_loadDraft(item),
      )),
    if(drafts.isEmpty)const FittedText('No se han creado borradores.'),
  ]);

  Widget _publication() => ListView(
    key:const Key('b3-brand-history'),
    padding:const EdgeInsets.all(22),
    children:[
      _header('Historial y restaurar marca',
        'Cada guardado crea una versión. Puedes restaurar cualquier '
        'identidad anterior sin aprobación ni compilación.'),
      Card(child:Padding(
        padding:const EdgeInsets.all(18),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          FittedText('Versión global activa: ${widget.liveBrand.version}',
            key:const Key('b3-active-version'),
            style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:8),
          FittedText('Nombre: ${widget.liveBrand.current.name}'),
          const SizedBox(height:12),
          OutlinedButton.icon(
            key:const Key('b3-refresh-history'),
            onPressed:_fetchBrandHistory,
            icon:const Icon(Icons.refresh_outlined),
            label:const FittedText('Consultar historial')),
        ]))),
      const SizedBox(height:12),
      if(brandHistory.isEmpty)const FittedText(
        'Pulsa Consultar historial para ver las versiones guardadas.'),
      for(final entry in brandHistory)
        Card(child:ListTile(
          leading:const Icon(Icons.history),
          title:FittedText('Versión ${entry['version']}'),
          subtitle:FittedText(entry['restored_from']==null
            ?'Cambio de identidad · ${entry['changed_at']}'
            :'Restaurada desde versión ${entry['restored_from']}'),
          trailing:OutlinedButton(
            onPressed:widget.liveBrand.saving
              ?null:()=>_restoreBrandVersion(
                (entry['version'] as num).toInt()),
            child:const FittedText('Restaurar')),
        )),
      const SizedBox(height:20),
      const FittedText('Las contraseñas, los datos privados y las '
        'credenciales nunca se incluyen en una versión de marca.'),
    ],
  );

  Widget _body() {
    if(loading)return const Center(child:CircularProgressIndicator());
    if(error!=null)return Center(child:Padding(padding:const EdgeInsets.all(24),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        FittedText(error!,textAlign:TextAlign.center),
        const SizedBox(height:12),
        FilledButton(onPressed:_reload,child:const FittedText('Reintentar')),
      ])));
    return switch(tab) {
      0=>_summary(),1=>_editor(),2=>MatchCalculatorAdmin(client:widget.liveBrand.client),
      3=>_library(),4=>_drafts(),_=>_publication(),
    };
  }

  @override
  Widget build(BuildContext context)=>LayoutBuilder(builder:(context,constraints){
    final wide=constraints.maxWidth>=860;
    return Scaffold(
      key:const Key('brand-admin-flutter-shell'),
      appBar:AppBar(
        title:Row(mainAxisSize:MainAxisSize.min,children:[
          MfdBranding(full:false,width:38),
          SizedBox(width:10),
          Flexible(child:FittedText(widget.liveBrand.current.name+' · Administrador',
            maxLines:1,overflow:TextOverflow.ellipsis)),
        ]),
        actions:[
          const Padding(padding:EdgeInsets.only(right:10),child:FittedLanguageSelector()),
          if(wide)Padding(padding:const EdgeInsets.only(right:10),
            child:Center(child:FittedText(widget.email,style:const TextStyle(fontSize:12)))),
          IconButton(
            onPressed:_reload,
            tooltip:FittedLocaleScope.translate(context,'Actualizar catálogo'),
            icon:const Icon(Icons.refresh)),
          IconButton(
            key:const Key('admin-sign-out'),
            onPressed:()=>widget.onSignOut(),
            tooltip:FittedLocaleScope.translate(context,'Cerrar sesión'),
            icon:const Icon(Icons.logout)),
        ],
      ),
      body:Row(children:[
        if(wide)NavigationRail(
          selectedIndex:tab,
          extended:constraints.maxWidth>=1130,
          labelType:constraints.maxWidth>=1130
            ?NavigationRailLabelType.none:NavigationRailLabelType.all,
          onDestinationSelected:(v)=>setState(()=>tab=v),
          destinations:[
            for(var i=0;i<_tabs.length;i++)
              NavigationRailDestination(
                icon:Icon(_icons[i]),label:FittedText(tabLabel(i))),
          ],
        ),
        Expanded(child:_body()),
      ]),
      bottomNavigationBar:wide?null:NavigationBar(
        selectedIndex:tab,
        onDestinationSelected:(v)=>setState(()=>tab=v),
        destinations:[
          for(var i=0;i<_tabs.length;i++)
            NavigationDestination(icon:Icon(_icons[i]),label:tabLabel(i)),
        ],
      ),
    );
  });
}
