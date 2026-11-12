import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/brand_admin_repository.dart';
import '../core/live_brand.dart';
import '../core/curator_repository.dart';
import '../core/activity_repository.dart';
import 'activities_b1.dart';
import 'admin_curated_activities_b2.dart';
import '../widgets/mfd_branding.dart';

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
    required this.liveBrand,
  });
  final BrandAdminRepository repository;
  final String email;
  final Future<void> Function() onSignOut;
  final CuratorRepository? curatorApi;
  final ActivityRepository? activityPreviewApi;
  final LiveBrandController liveBrand;

  @override
  State<BrandAdminHome> createState() => _BrandAdminHomeState();
}

class _BrandAdminHomeState extends State<BrandAdminHome> {
  static const _tabs = <String>[
    'Resumen', 'Marca en vivo', 'Biblioteca', 'Borradores', 'Historial'
  ];
  static const _icons = <IconData>[
    Icons.space_dashboard_outlined,
    Icons.palette_outlined,
    Icons.collections_outlined,
    Icons.layers_outlined,
    Icons.history_outlined
  ];
  static const _logoNames = <String>[
    'Monograma', 'Cadencia', 'Cumbres', 'Vínculo', 'Pulso',
    'Brújula', 'Trayectoria', 'Horizonte', 'Geometría', 'Movimiento',
  ];
  static const _logoIcons = <IconData>[
    Icons.change_history, Icons.graphic_eq, Icons.landscape_outlined,
    Icons.hub_outlined, Icons.multiline_chart, Icons.explore_outlined,
    Icons.timeline, Icons.waves_outlined, Icons.diamond_outlined,
    Icons.auto_graph_outlined,
  ];
  static const _paletteSeeds = <Map<String, String>>[
    {'name':'Bosque', 'primary':'#28463D','accent':'#B49A6A','background':'#F7F5F0'},
    {'name':'Azul noche', 'primary':'#152D3D','accent':'#859EA3','background':'#F4F5F2'},
    {'name':'Tierra', 'primary':'#5A4838','accent':'#B2936A','background':'#FAF5EB'},
    {'name':'Pizarra', 'primary':'#36434A','accent':'#8D9A9D','background':'#F4F5F4'},
    {'name':'Salvia', 'primary':'#455D4B','accent':'#9AA57D','background':'#F8F7F1'},
  ];

  final name = TextEditingController(text:'My Fitness Date');
  final tagline = TextEditingController(text:'Conexiones con intención.');
  final headline = TextEditingController(text:'Personas afines a tu forma de vivir.');
  final description = TextEditingController(
    text:'Una comunidad para personas que valoran la vida activa y las relaciones serias.');
  final paletteName = TextEditingController(text:'Bosque');
  final primary = TextEditingController(text:'#28463D');
  final accent = TextEditingController(text:'#B49A6A');
  final background = TextEditingController(text:'#F7F5F0');
  final draftTitle = TextEditingController(text:'Propuesta elegante 40+');
  int tab = 0;
  int logoIndex = 0;
  String? selectedLogoAsset;
  String font = 'Georgia';
  String license = 'open';
  String selectedUploadKind = 'logo';
  String layout = 'editorial';
  bool dark = false;
  bool mobilePreview = false;
  bool busy = false;
  bool loading = true;
  String? error;
  Timer? _brandTimer;
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
      _hydrateLiveBrand();
    } else {
      unawaited(widget.liveBrand.refresh());
    }
    _reload();
  }

  void _redraw() {
    if(mounted)setState(() {});
    if(!_brandHydrating)_queueBrandSave();
  }

  @override
  void dispose() {
    _brandTimer?.cancel();
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
      content: Text(text),
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

  Future<void> _savePalette() async {
    try {
      await widget.repository.createPalette(paletteName.text, colors);
      await _reload();
      _notice('Paleta incorporada al catálogo administrativo.');
    } catch (_) { _notice('No fue posible guardar la paleta. Verifica los colores y MFA.',bad:true); }
  }


  void _observeBrand() {
    if(!mounted || !widget.liveBrand.loaded) return;
    if(!_brandReady || (!_brandSaving && _brandTimer==null &&
        widget.liveBrand.version>_brandHydratedVersion)) {
      _hydrateLiveBrand();
    }
  }

  void _hydrateLiveBrand() {
    if(!mounted) return;
    _brandHydrating=true;
    _brandTimer?.cancel();
    _brandTimer=null;
    final s=widget.liveBrand.current;
    setState((){
      name.text=s.name;
      tagline.text=s.tagline;
      headline.text=s.title;
      description.text=s.description;
      paletteName.text=s.paletteName;
      primary.text=s.primary;
      accent.text=s.accent;
      background.text=s.background;
      font=s.font;
      dark=s.dark;
      layout=s.layout;
      if(s.logo.startsWith('catalog:')) {
        logoIndex=int.tryParse(s.logo.substring(8))??0;
        selectedLogoAsset=null;
      } else {
        selectedLogoAsset=s.logo;
      }
      selectedImages
        ..clear()
        ..addAll(s.media);
      _brandHydratedVersion=widget.liveBrand.version;
      _brandReady=true;
      brandStatus='Configuración global activa · versión ${widget.liveBrand.version}';
    });
    _brandHydrating=false;
  }

  void _queueBrandSave() {
    if(!_brandReady || _brandHydrating || !mounted)return;
    _brandTimer?.cancel();
    setState(() => brandStatus='Cambios pendientes de guardar…');
    _brandTimer=Timer(const Duration(milliseconds:850),(){
      _brandTimer=null;
      unawaited(_saveBrandGlobally());
    });
  }

  Future<void> _saveBrandGlobally() async {
    if(!_brandReady || !mounted)return;
    if(_brandSaving){
      _brandDirty=true;
      return;
    }
    final logo=_settings()['logo'].toString();
    if(!validPalette ||
       name.text.trim().length<2 || name.text.trim().length>60 ||
       tagline.text.trim().length<2 || tagline.text.trim().length>120 ||
       headline.text.trim().length<8 || headline.text.trim().length>180 ||
       description.text.trim().length<10 || description.text.trim().length>600 ||
       paletteName.text.trim().length<2 ||
       !const ['Georgia','Palatino','Garamond','Arial'].contains(font) ||
       (selectedLogoAsset!=null &&
         !LiveBrandSettings.safeAssetUrl(selectedLogoAsset!)) ||
       (logo.startsWith('https://') &&
        !LiveBrandSettings.safeAssetUrl(logo)) ||
       selectedImages.values.any((v)=>!LiveBrandSettings.safeAssetUrl(v))) {
      setState(()=>brandStatus='Completa campos válidos y usa imágenes públicas.');
      return;
    }
    final proposed=LiveBrandSettings.fromMap(_settings());
    if(widget.liveBrand.asJson == 
       const JsonEncoder().convert(proposed.toMap())) {
      setState(()=>brandStatus='Guardado y visible para todos · versión ${widget.liveBrand.version}');
      return;
    }
    _brandSaving=true;
    if(mounted)setState(()=>brandStatus='Guardando para todos…');
    try {
      await widget.liveBrand.save(proposed);
      _brandHydratedVersion=widget.liveBrand.version;
      if(mounted)setState(()=>brandStatus=
        'Guardado y visible para todos · versión ${widget.liveBrand.version}');
    } catch (_) {
      if(!mounted)return;
      _hydrateLiveBrand();
      setState(()=>brandStatus=
        'No se guardó. Se restauró la última versión publicada. Verifica MFA o conexión.');
    } finally {
      _brandSaving=false;
      if(_brandDirty){
        _brandDirty=false;
        _queueBrandSave();
      }
    }
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
      _brandTimer?.cancel();
      _brandTimer=null;
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
        name.text=(settings['name']??'My Fitness Date').toString();
        tagline.text=(settings['tagline']??'').toString();
        headline.text=(settings['title']??'').toString();
        description.text=(settings['description']??'').toString();
        paletteName.text=(settings['paletteName']??'Personalizada').toString();
        primary.text=c['primary'].toString();
        accent.text=c['accent'].toString();
        background.text=c['background'].toString();
        font=(settings['font']??'Georgia').toString();
        final logo=(settings['logo']??'catalog:0').toString();
        selectedLogoAsset=logo.startsWith('asset:')?logo.substring(6):null;
        final parsed=int.tryParse(logo.replaceFirst('catalog:',''));
        logoIndex=(parsed??0).clamp(0,9);
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
        _queueBrandSave();
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
        _queueBrandSave();
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
      Text(title,style:Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height:7),
      Text(subtitle,style:Theme.of(context).textTheme.bodyMedium),
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
        Text('Brand Studio',style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:8),
        const Text('Configura nombre, paletas, textos, logotipos y portadas. '
          'Se guardan globalmente sin revisión ni despliegue adicional.'),
        const SizedBox(height:12),
        FilledButton.icon(
          onPressed:()=>setState(()=>tab=1),
          icon:const Icon(Icons.design_services_outlined),
          label:const Text('Editar marca en vivo'),
        ),
      ],
    ))),
    if (widget.curatorApi != null) ...[
      const SizedBox(height:14),
      Card(child:Padding(padding:const EdgeInsets.all(20),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Actividades deportivas',
            style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:8),
          const Text('Publica actividades verificadas para los miembros y '
            'mira cómo se ven en la aplicación, sin salir de tu cuenta '
            'administrativa ni solicitar un nuevo despliegue.'),
          const SizedBox(height:12),
          FilledButton.icon(
            key:const Key('b2-admin-open-curation'),
            onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
              builder:(_)=>AdminCuratedActivitiesB2(api:widget.curatorApi!))),
            icon:const Icon(Icons.event_available_outlined),
            label:const Text('Administrar actividades')),
          if(widget.activityPreviewApi!=null) ...[
            const SizedBox(height:10),
            OutlinedButton.icon(
              key:const Key('b2-admin-member-preview'),
              onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
                builder:(_)=>ActivitiesB1(
                  api:widget.activityPreviewApi!,readOnly:true))),
              icon:const Icon(Icons.visibility_outlined),
              label:const Text('Ver como miembro (solo lectura)')),
          ],
        ]))),
    ],
    const SizedBox(height:14),
    const Card(child:Padding(padding:EdgeInsets.all(18),
      child:Text('Los cambios de apariencia internos se guardan sin otro build. '
        'El icono instalado, tiendas y permisos móviles continúan requiriendo publicación de software.'))),
  ]);

  Widget _stat(String label,int value,IconData icon)=>SizedBox(
    width:205,child:Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        Icon(icon,size:30),
        const SizedBox(height:14),
        Text('$value',style:Theme.of(context).textTheme.headlineMedium),
        Text(label),
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
        Expanded(child:Text(brandStatus!,key:const Key('b3-save-status'))),
        if(!_brandReady) TextButton(onPressed:()=>widget.liveBrand.refresh(),
          child:const Text('Sincronizar')),
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
          Text('Nombre y comunicación',style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:12),
          _field(name,'Nombre de la aplicación'),
          _field(tagline,'Lema'),
          _field(headline,'Título de portada'),
          _field(description,'Presentación',lines:3),
        ]))),
      const SizedBox(height:10),
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Paletas y colores',style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:8),
          Wrap(spacing:7,runSpacing:7,children:[
            for(final p in _paletteSeeds)
              ChoiceChip(label:Text(p['name']!),
                selected:paletteName.text==p['name'],
                onSelected:(_)=>_applyPalette(p)),
          ]),
          if(palettes.isNotEmpty) ...[
            const SizedBox(height:12),
            const Text('Mis paletas guardadas'),
            Wrap(spacing:6,runSpacing:6,children:[
              for(final p in palettes)
                ActionChip(label:Text(p['name'].toString()),
                  onPressed:(){
                    final c=Map<String,dynamic>.from(p['colors'] as Map);
                    _applyPalette({'name':p['name'].toString(),
                      for(final k in ['primary','accent','background'])
                        k:c[k].toString()});
                  }),
            ]),
          ],
          const SizedBox(height:13),
          _field(paletteName,'Nombre de la nueva paleta'),
          Row(children:[
            Expanded(child:_field(primary,'Primario HEX')),
            const SizedBox(width:8),
            Expanded(child:_field(accent,'Acento HEX')),
          ]),
          _field(background,'Fondo HEX'),
          FilledButton.tonalIcon(
            onPressed:validPalette?_savePalette:null,
            icon:const Icon(Icons.add_circle_outline),
            label:const Text('Crear paleta en catálogo'),
          ),
        ]))),
      const SizedBox(height:10),
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Tipografía',style:Theme.of(context).textTheme.titleLarge),
          DropdownButtonFormField<String>(
            key:ValueKey('font-$font'),initialValue:font,
            decoration:const InputDecoration(labelText:'Familia de prueba'),
            items:[
              for(final f in ['Georgia','Palatino','Garamond','Arial'])
                DropdownMenuItem(value:f,child:Text(f)),
              if(font.startsWith('asset:'))
                DropdownMenuItem(value:font,
                  child:const Text('Fuente WOFF2 cargada (requiere compilación)')),
            ],
            onChanged:(v){setState(()=>font=v??'Georgia');_queueBrandSave();},
          ),
          const SizedBox(height:8),
          const Text('Las fuentes WOFF2 se conservan en la biblioteca. '
            'Su visualización nativa completa requiere procesarlas para Flutter.',
            style:TextStyle(fontSize:12)),
        ]))),
      const SizedBox(height:10),
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Logotipos del catálogo',style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:12),
          Wrap(spacing:8,runSpacing:8,children:[
            for(var i=0;i<_logoNames.length;i++)
              ChoiceChip(
                key:Key('admin-logo-$i'),
                avatar:Icon(_logoIcons[i],size:19),
                label:Text(_logoNames[i]),
                selected:selectedLogoAsset==null&&logoIndex==i,
                onSelected:(_){setState((){
                  selectedLogoAsset=null;logoIndex=i;
                });_queueBrandSave();},
              ),
          ]),
          if(selectedLogoAsset!=null)
            TextButton(
              onPressed:(){setState(()=>selectedLogoAsset=null);_queueBrandSave();},
              child:const Text('Volver a los logos del catálogo')),
          const SizedBox(height:10),
          SwitchListTile(
            title:const Text('Vista oscura'),
            value:dark,
            onChanged:(v){setState(()=>dark=v);_queueBrandSave();}),
          DropdownButtonFormField<String>(
            key:ValueKey('layout-$layout'),
            initialValue:layout,
            items:const [
              DropdownMenuItem(value:'editorial',child:Text('Editorial')),
              DropdownMenuItem(value:'minimal',child:Text('Minimalista')),
            ],
            onChanged:(v){setState(()=>layout=v??'editorial');_queueBrandSave();},
            decoration:const InputDecoration(labelText:'Distribución'),
          ),
        ]))),
      const SizedBox(height:12),
      const ListTile(
        key:Key('b3-auto-publish-label'),
        leading:Icon(Icons.cloud_done_outlined),
        title:Text('Guardado automático activo'),
        subtitle:Text('No hay solicitudes de revisión ni builds por cada cambio.')),
    ]);

  Widget _preview(){
    final p=_color(primary.text,const Color(0xFF28463D));
    final a=_color(accent.text,const Color(0xFFB49A6A));
    final bg=_color(background.text,const Color(0xFFF7F5F0));
    final foreground=dark?Colors.white:const Color(0xFF182923);
    final bodyColor=dark?const Color(0xFF172621):bg;
    final heroAssetId=selectedImages[mobilePreview?'cover_mobile':'cover_desktop'];
    final heroBytes=heroAssetId==null?null:downloaded[heroAssetId];
    final logoBytes=selectedLogoAsset==null?null:downloaded[selectedLogoAsset];
    final ImageProvider? heroProvider=heroBytes!=null
      ? MemoryImage(heroBytes)
      : heroAssetId!=null && LiveBrandSettings.safeAssetUrl(heroAssetId)
        ? NetworkImage(heroAssetId) : null;
    return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(
      crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Text('Vista previa en vivo',style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:8),
        Wrap(children:[
          FilterChip(label:const Text('Web'),selected:!mobilePreview,
            onSelected:(_)=>setState(()=>mobilePreview=false)),
          const SizedBox(width:8),
          FilterChip(label:const Text('Móvil'),selected:mobilePreview,
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
                color:dark?const Color(0xFF29362E):Colors.white,
                child:Row(children:[
                  if(logoBytes!=null)
                    Image.memory(logoBytes,width:35,height:35)
                  else if(selectedLogoAsset!=null &&
                    LiveBrandSettings.safeAssetUrl(selectedLogoAsset!))
                    Image.network(selectedLogoAsset!,width:35,height:35)
                  else if(logoIndex==0)
                    Image.asset('assets/branding/mfd_icon.webp',
                      width:35,height:35,fit:BoxFit.contain)
                  else
                    Icon(_logoIcons[logoIndex],color:p,size:32),
                  const SizedBox(width:8),
                  Expanded(child:Text(name.text.isEmpty?'Mi marca':name.text,
                    maxLines:2,overflow:TextOverflow.ellipsis,
                    style:TextStyle(color:foreground,fontSize:19,
                      fontWeight:FontWeight.w600,
                      fontFamily:font.startsWith('asset:')?null:font))),
                ])),
              Stack(children:[
                Container(
                  constraints:const BoxConstraints(minHeight:280),
                  decoration:BoxDecoration(
                    gradient:LinearGradient(colors:[p,p.withValues(alpha:.65)]),
                    image:heroProvider==null?null:DecorationImage(
                      image:heroProvider,fit:BoxFit.cover,
                      colorFilter:ColorFilter.mode(
                        p.withValues(alpha:.40),BlendMode.darken))),
                ),
                Padding(padding:const EdgeInsets.all(26),
                  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    const Text('CONEXIONES CON INTENCIÓN',style:TextStyle(
                      fontSize:11,color:Colors.white70,letterSpacing:2)),
                    const SizedBox(height:15),
                    Text(headline.text,
                      style:TextStyle(fontFamily:font.startsWith('asset:')?null:font,
                        fontSize:mobilePreview?28:34,
                        color:Colors.white,height:1.22)),
                    const SizedBox(height:16),
                    Text(description.text,style:const TextStyle(
                      color:Colors.white,fontSize:15,height:1.5)),
                    const SizedBox(height:18),
                    Container(
                      decoration:BoxDecoration(
                        color:a,borderRadius:BorderRadius.circular(10)),
                      padding:const EdgeInsets.all(12),
                      child:const Text('Conocer nuestra propuesta',
                        style:TextStyle(color:Colors.black87,fontWeight:FontWeight.w700))),
                  ])),
              ]),
              Container(
                padding:const EdgeInsets.all(20),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(tagline.text,style:TextStyle(
                    color:foreground,fontWeight:FontWeight.bold,fontSize:18)),
                  const SizedBox(height:7),
                  Text('Cómo me muevo · Cómo vivo · Cómo me relaciono',
                    style:TextStyle(color:foreground)),
                ]),
              ),
            ]),
          ),
        )),
        const SizedBox(height:12),
        Text('El diseño de la portada ya usa esta marca global. '
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
          decoration:const InputDecoration(labelText:'Tipo de recurso'),
          items:const [
            DropdownMenuItem(value:'logo',child:Text('Logo PNG o WebP')),
            DropdownMenuItem(value:'font',child:Text('Tipografía WOFF2')),
            DropdownMenuItem(value:'cover_desktop',child:Text('Portada escritorio')),
            DropdownMenuItem(value:'cover_mobile',child:Text('Portada móvil')),
            DropdownMenuItem(value:'login_image',child:Text('Imagen de acceso')),
            DropdownMenuItem(value:'onboarding_image',child:Text('Imagen de onboarding')),
            DropdownMenuItem(value:'app_image',child:Text('Imagen interior')),
            DropdownMenuItem(value:'illustration',child:Text('Ilustración')),
          ],
          onChanged:(v)=>setState(()=>selectedUploadKind=v??'logo'),
        ),
        if(selectedUploadKind=='font') ...[
          const SizedBox(height:12),
          DropdownButtonFormField<String>(
            initialValue:license,
            decoration:const InputDecoration(labelText:'Licencia de uso declarada'),
            items:const [
              DropdownMenuItem(value:'open',child:Text('Licencia abierta compatible')),
              DropdownMenuItem(value:'owned',child:Text('Soy titular de los derechos')),
              DropdownMenuItem(value:'licensed',child:Text('Licencia comercial válida')),
            ],
            onChanged:(v)=>setState(()=>license=v??'open'),
          ),
        ],
        const SizedBox(height:14),
        FilledButton.icon(
          key:const Key('admin-upload-brand-asset'),
          onPressed:busy?null:_upload,
          icon:const Icon(Icons.upload_file_outlined),
          label:Text(busy?'Cargando...':'Seleccionar y subir archivo privado'),
        ),
        const SizedBox(height:8),
        const Text('Imágenes PNG/WebP/JPG hasta 8 MiB; fuentes WOFF2 hasta '
          '2 MiB. No se admiten SVG externos activos.',style:TextStyle(fontSize:12)),
      ],
    ))),
    const SizedBox(height:16),
    for(final item in assets)
      Card(child:ListTile(
        leading:Icon(item['asset_kind']=='font'?Icons.text_fields:
          item['asset_kind']=='logo'?Icons.auto_awesome_mosaic:Icons.image_outlined),
        title:Text(item['name'].toString(),maxLines:1,overflow:TextOverflow.ellipsis),
        subtitle:Text('${item['asset_kind']} · ${((item['bytes'] as num)/1024).ceil()} KB'),
        trailing:const Icon(Icons.check_circle_outline),
        onTap:()async{
          await _loadAsset(item);
          if(mounted)setState(()=>tab=1);
          _notice('Recurso seleccionado para el borrador, no para producción.');
        },
      )),
    if(assets.isEmpty)const Padding(
      padding:EdgeInsets.all(20),
      child:Text('Aún no hay recursos privados.')),
  ]);

  Widget _drafts()=>ListView(padding:const EdgeInsets.all(22),children:[
    _header('Borradores y versiones',
      'Guarda, consulta y recupera configuraciones. Ninguna cambia la marca pública.'),
    _field(draftTitle,'Título del borrador'),
    FilledButton.icon(
      onPressed:busy?null:_saveDraft,
      icon:const Icon(Icons.save_outlined),
      label:Text(draft==null?'Crear borrador':'Guardar nueva revisión'),
    ),
    const SizedBox(height:12),
    OutlinedButton(
      onPressed:()=>setState((){
        draft=null;revisions=[];draftTitle.text='Nueva propuesta';
      }),
      child:const Text('Comenzar una propuesta nueva'),
    ),
    if(draft!=null) ...[
      const SizedBox(height:14),
      OutlinedButton.icon(onPressed:_fetchRevisions,
        icon:const Icon(Icons.history),
        label:const Text('Ver historial del borrador')),
      for(final rev in revisions)
        ListTile(
          leading:const Icon(Icons.history_toggle_off),
          title:Text('Revisión ${rev['revision']}'),
          subtitle:Text(rev['recorded_at'].toString()),
        ),
    ],
    const SizedBox(height:20),
    Text('Diseños guardados',style:Theme.of(context).textTheme.titleLarge),
    for(final item in drafts)
      Card(child:ListTile(
        title:Text(item['title'].toString()),
        subtitle:Text('Revisión ${item['revision']} · ${item['updated_at']}'),
        trailing:const Icon(Icons.edit_outlined),
        onTap:()=>_loadDraft(item),
      )),
    if(drafts.isEmpty)const Text('No se han creado borradores.'),
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
          Text('Versión global activa: ${widget.liveBrand.version}',
            key:const Key('b3-active-version'),
            style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:8),
          Text('Nombre: ${widget.liveBrand.current.name}'),
          const SizedBox(height:12),
          OutlinedButton.icon(
            key:const Key('b3-refresh-history'),
            onPressed:_fetchBrandHistory,
            icon:const Icon(Icons.refresh_outlined),
            label:const Text('Consultar historial')),
        ]))),
      const SizedBox(height:12),
      if(brandHistory.isEmpty)const Text(
        'Pulsa Consultar historial para ver las versiones guardadas.'),
      for(final entry in brandHistory)
        Card(child:ListTile(
          leading:const Icon(Icons.history),
          title:Text('Versión ${entry['version']}'),
          subtitle:Text(entry['restored_from']==null
            ?'Cambio de identidad · ${entry['changed_at']}'
            :'Restaurada desde versión ${entry['restored_from']}'),
          trailing:OutlinedButton(
            onPressed:widget.liveBrand.saving
              ?null:()=>_restoreBrandVersion(
                (entry['version'] as num).toInt()),
            child:const Text('Restaurar')),
        )),
      const SizedBox(height:20),
      const Text('Las contraseñas, los datos privados y las '
        'credenciales nunca se incluyen en una versión de marca.'),
    ],
  );

  Widget _body() {
    if(loading)return const Center(child:CircularProgressIndicator());
    if(error!=null)return Center(child:Padding(padding:const EdgeInsets.all(24),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        Text(error!,textAlign:TextAlign.center),
        const SizedBox(height:12),
        FilledButton(onPressed:_reload,child:const Text('Reintentar')),
      ])));
    return switch(tab) {
      0=>_summary(),1=>_editor(),2=>_library(),3=>_drafts(),_=>_publication(),
    };
  }

  @override
  Widget build(BuildContext context)=>LayoutBuilder(builder:(context,constraints){
    final wide=constraints.maxWidth>=860;
    return Scaffold(
      key:const Key('brand-admin-flutter-shell'),
      appBar:AppBar(
        title:const Row(mainAxisSize:MainAxisSize.min,children:[
          MfdBranding(full:false,width:38),
          SizedBox(width:10),
          Flexible(child:Text('My Fitness Date · Administrador',
            maxLines:1,overflow:TextOverflow.ellipsis)),
        ]),
        actions:[
          if(wide)Padding(padding:const EdgeInsets.only(right:10),
            child:Center(child:Text(widget.email,style:const TextStyle(fontSize:12)))),
          IconButton(
            onPressed:_reload,
            tooltip:'Actualizar catálogo',
            icon:const Icon(Icons.refresh)),
          IconButton(
            key:const Key('admin-sign-out'),
            onPressed:()=>widget.onSignOut(),
            tooltip:'Cerrar sesión',
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
                icon:Icon(_icons[i]),label:Text(_tabs[i])),
          ],
        ),
        Expanded(child:_body()),
      ]),
      bottomNavigationBar:wide?null:NavigationBar(
        selectedIndex:tab,
        onDestinationSelected:(v)=>setState(()=>tab=v),
        destinations:[
          for(var i=0;i<_tabs.length;i++)
            NavigationDestination(icon:Icon(_icons[i]),label:_tabs[i]),
        ],
      ),
    );
  });
}
