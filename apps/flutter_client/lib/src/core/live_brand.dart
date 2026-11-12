import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/fitness_date_theme.dart';

/// Only display-safe global values. No private draft or credential fields.
class LiveBrandSettings {
  const LiveBrandSettings({
    required this.name,
    required this.tagline,
    required this.title,
    required this.description,
    required this.paletteName,
    required this.primary,
    required this.accent,
    required this.background,
    required this.font,
    required this.logo,
    required this.media,
    required this.mode,
    required this.layout,
  });

  final String name, tagline, title, description, paletteName;
  final String primary, accent, background, font, logo, mode, layout;
  final Map<String, String> media;

  static const fallback = LiveBrandSettings(
    name: 'My Fitness Date',
    tagline: 'Conexiones con intención.',
    title: 'Tu próxima conexión también puede compartir tu ritmo.',
    description: 'Muestra quién eres, lo que te apasiona y cómo vives el deporte.',
    paletteName: 'Original',
    primary: '#FF617B',
    accent: '#C8FF6B',
    background: '#0A0D16',
    font: 'Arial',
    logo: 'catalog:0',
    media: <String, String>{},
    mode: 'dark',
    layout: 'editorial',
  );

  static final _hex = RegExp(r'^#[0-9a-fA-F]{6}$');
  static final _asset = RegExp(
    r'^https://jtrdvnwbxpfdnbzasvcj\.supabase\.co/storage/v1/object/public/'
    r'mfd-brand-live/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-'
    r'[0-9a-f]{4}-[0-9a-f]{12}/[a-zA-Z0-9_-]{4,100}\.(png|jpg|webp)$',
  );

  static bool safeAssetUrl(String input) => _asset.hasMatch(input);

  static LiveBrandSettings fromMap(dynamic value) {
    if (value is! Map) return fallback;
    final m = Map<String, dynamic>.from(value);
    final colors = m['colors'] is Map
        ? Map<String, dynamic>.from(m['colors'] as Map) : <String, dynamic>{};
    String str(String key, String def, int max) {
      final v = m[key];
      return v is String && v.trim().isNotEmpty && v.length <= max
          ? v.trim() : def;
    }
    String hex(String key, String def) {
      final v = colors[key];
      return v is String && _hex.hasMatch(v) ? v : def;
    }
    final rawMedia = m['media'] is Map
        ? Map<String, dynamic>.from(m['media'] as Map) : <String, dynamic>{};
    final media = <String, String>{};
    for (final key in const ['cover_desktop', 'cover_mobile', 'app_image']) {
      final candidate = rawMedia[key];
      if (candidate is String && safeAssetUrl(candidate)) {
        media[key] = candidate;
      }
    }
    final selectedFont = str('font', fallback.font, 20);
    final selectedLogo = str('logo', fallback.logo, 300);
    final selectedMode = str('mode', fallback.mode, 10);
    final selectedLayout = str('layout', fallback.layout, 20);
    return LiveBrandSettings(
      name: str('name', fallback.name, 60),
      tagline: str('tagline', fallback.tagline, 120),
      title: str('title', fallback.title, 180),
      description: str('description', fallback.description, 600),
      paletteName: str('paletteName', fallback.paletteName, 70),
      primary: hex('primary', fallback.primary),
      accent: hex('accent', fallback.accent),
      background: hex('background', fallback.background),
      font: const ['Arial', 'Georgia', 'Palatino', 'Garamond']
          .contains(selectedFont) ? selectedFont : fallback.font,
      logo: RegExp(r'^catalog:[0-9]$').hasMatch(selectedLogo) ||
          safeAssetUrl(selectedLogo) ? selectedLogo : fallback.logo,
      media: media,
      mode: const ['dark', 'light'].contains(selectedMode)
          ? selectedMode : fallback.mode,
      layout: const ['editorial', 'minimal'].contains(selectedLayout)
          ? selectedLayout : fallback.layout,
    );
  }

  Map<String, dynamic> toMap() => {
    'name':name,
    'tagline':tagline,
    'title':title,
    'description':description,
    'paletteName':paletteName,
    'colors': {
      'primary':primary, 'accent':accent, 'background':background,
    },
    'font':font,
    'logo':logo,
    'media':media,
    'mode':mode,
    'layout':layout,
  };

  Color get primaryColor => _color(primary);
  Color get accentColor => _color(accent);
  Color get backgroundColor => _color(background);
  bool get dark => mode == 'dark';

  static Color _color(String hex) =>
      Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));

  ThemeData toTheme() {
    final brightness = dark ? Brightness.dark : Brightness.light;
    final bg = backgroundColor;
    final fg = bg.computeLuminance() < .35 ? Colors.white : Colors.black87;
    final p = primaryColor;
    final a = accentColor;
    final onP = p.computeLuminance() > .3 ? Colors.black : Colors.white;
    final onA = a.computeLuminance() > .3 ? Colors.black : Colors.white;
    final base = dark ? FitDateTheme.dark() : ThemeData.light(useMaterial3:true);
    final scheme = ColorScheme.fromSeed(
      seedColor:p,brightness:brightness,
    ).copyWith(
      primary:p,onPrimary:onP,secondary:a,onSecondary:onA,
      surface:bg,onSurface:fg,
    );
    return base.copyWith(
      colorScheme:scheme,
      scaffoldBackgroundColor:bg,
      canvasColor:bg,
      cardTheme:CardThemeData(
        color:dark ? Color.lerp(bg, Colors.white, .07) : Colors.white,
        elevation:0,
        shape:RoundedRectangleBorder(
          borderRadius:BorderRadius.circular(18),
          side:BorderSide(color:p.withValues(alpha:.18)),
        ),
      ),
      textTheme:base.textTheme.apply(
        fontFamily:font,bodyColor:fg,displayColor:fg,
      ),

      filledButtonTheme:FilledButtonThemeData(
        style:FilledButton.styleFrom(
          backgroundColor:p,foregroundColor:onP,
        ),
      ),
      outlinedButtonTheme:OutlinedButtonThemeData(
        style:OutlinedButton.styleFrom(foregroundColor:fg),
      ),
    );
  }
}

class LiveBrandController extends ChangeNotifier {
  LiveBrandController(this.client);
  final SupabaseClient client;
  LiveBrandSettings current = LiveBrandSettings.fallback;
  int version = 0;
  bool loaded = false;
  bool saving = false;
  String? lastError;
  bool _disposed = false;
  bool _loading = false;

  void _emit() { if (!_disposed) notifyListeners(); }

  Future<void> refresh() async {
    if (_loading || saving || _disposed) return;
    _loading = true;
    try {
      final value = await client.from('mfd_brand_live')
        .select('version,settings').eq('id',true).single()
        .timeout(const Duration(seconds: 12));
      final incomingVersion = (value['version'] as num).toInt();
      if (!loaded || incomingVersion > version) {
        current = LiveBrandSettings.fromMap(value['settings']);
        version = incomingVersion;
        loaded = true;
        lastError = null;
        _emit();
      }
    } catch (_) {
      // The last known-good brand is preserved on transient connectivity loss.
      lastError = 'Sincronización de identidad pendiente.';
      _emit();
    } finally {
      _loading = false;
    }
  }

  Future<void> save(LiveBrandSettings proposed) async {
    if (saving) throw StateError('Ya se está guardando un cambio');
    saving = true;
    _emit();
    try {
      final response = await client.rpc('brand_set_live',params:{
        'p_settings': proposed.toMap(),
        'p_expected_version': version,
      }).timeout(const Duration(seconds: 15));
      if (response is! Map) throw StateError('Respuesta inválida');
      final status = response['status']?.toString();
      if (status != 'saved') {
        throw StateError(status == 'conflict'
          ? 'La marca cambió en otra sesión. Recarga la configuración.'
          : status == 'forbidden'
          ? 'Se requiere una sesión de propietario con MFA verificado.'
          : 'Revisa los campos e imágenes de la marca.');
      }
      current = LiveBrandSettings.fromMap(response['settings']);
      version = (response['version'] as num).toInt();
      loaded = true;
      lastError = null;
    } catch (e) {
      lastError = e.toString().replaceFirst('Bad state: ', '');
      rethrow;
    } finally {
      saving = false;
      _emit();
    }
  }

  Future<List<Map<String, dynamic>>> history() async {
    final result = await client.rpc('brand_history_live')
        .timeout(const Duration(seconds: 12));
    return (result as List).map(
      (v) => Map<String, dynamic>.from(v as Map),
    ).toList();
  }

  Future<void> restore(int target) async {
    if (saving) throw StateError('Otra operación sigue en curso');
    saving = true;
    _emit();
    try {
      final value = await client.rpc('brand_restore_live',params:{
        'p_version':target,'p_expected_version':version,
      }).timeout(const Duration(seconds: 15));
      if (value is! Map || value['status'] != 'saved') {
        throw StateError('No se pudo restaurar esta versión.');
      }
      current = LiveBrandSettings.fromMap(value['settings']);
      version = (value['version'] as num).toInt();
      loaded = true;
      lastError = null;
    } finally {
      saving = false;
      _emit();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  String get asJson => jsonEncode(current.toMap());
}

/// All Flutter screens in a given session see the same approved brand.
class LiveBrandScope extends InheritedWidget {
  const LiveBrandScope({
    super.key,
    required this.brand,
    required super.child,
  });
  final LiveBrandSettings brand;
  static LiveBrandSettings of(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<LiveBrandScope>()?.brand
      ?? LiveBrandSettings.fallback;

  @override
  bool updateShouldNotify(LiveBrandScope oldWidget) =>
    !identical(oldWidget.brand, brand);
}
