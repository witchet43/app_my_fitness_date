import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Brand administration uses authenticated Supabase client and RLS / AAL2.
/// No service-role credentials are used on a device. A public brand release
/// remains an explicitly separate, reviewed deployment operation.
class BrandAdminRepository {
  BrandAdminRepository(this.client);
  final SupabaseClient client;

  String get ownerId {
    final id = client.auth.currentUser?.id;
    if (id == null || id.isEmpty) throw StateError('Sin identidad válida');
    return id;
  }

  Future<bool> isAdministrator() async =>
      await client.rpc('brand_admin_status') == true;

  Future<bool> hasVerifiedMfa() async =>
      await client.rpc('brand_admin_session') == true;

  Future<List<Map<String, dynamic>>> loadPalettes() async =>
      List<Map<String, dynamic>>.from(
          await client.from('brand_palettes').select().order('created_at', ascending: false));

  Future<List<Map<String, dynamic>>> loadDrafts() async =>
      List<Map<String, dynamic>>.from(
          await client.from('brand_design_drafts').select().order('updated_at', ascending: false));

  Future<List<Map<String, dynamic>>> loadAssets() async =>
      List<Map<String, dynamic>>.from(
          await client.from('brand_assets').select().order('created_at', ascending: false));

  Future<List<Map<String, dynamic>>> loadRevisions(String id) async =>
      List<Map<String, dynamic>>.from(
          await client.from('brand_design_revisions').select()
              .eq('draft_id', id).order('revision', ascending: false));

  Future<List<Map<String, dynamic>>> loadReleaseRequests() async =>
      List<Map<String, dynamic>>.from(
          await client.from('brand_release_requests').select()
              .order('requested_at', ascending: false));

  static bool validHex(String value) =>
      RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value);

  Future<void> createPalette(String name, Map<String, String> colors) async {
    if (name.trim().length < 2 || name.length > 70 ||
        !const ['primary', 'accent', 'background']
            .every((k) => validHex(colors[k] ?? ''))) {
      throw const FormatException('Nombre o colores inválidos');
    }
    await client.from('brand_palettes').insert({
      'name': name.trim(),
      'colors': colors,
      'created_by': ownerId,
    });
  }

  /// Insert or compare-and-swap the revision. Database trigger keeps immutable
  /// snapshots. No ability to mark a draft as published is granted here.
  Future<Map<String, dynamic>> saveDraft({
    required String title,
    required Map<String, dynamic> settings,
    Map<String, dynamic>? prior,
  }) async {
    if (title.trim().length < 2 || title.length > 100) {
      throw const FormatException('Nombre del borrador inválido');
    }
    if (prior == null) {
      final rows = await client.from('brand_design_drafts').insert({
        'title': title.trim(), 'settings': settings,
        'created_by': ownerId, 'updated_by': ownerId,
      }).select();
      if (rows.length != 1) throw StateError('No se guardó el borrador');
      return Map<String, dynamic>.from(rows.first);
    }
    final revision = (prior['revision'] as num).toInt();
    final rows = await client.from('brand_design_drafts').update({
      'title': title.trim(),
      'settings': settings,
      'revision': revision + 1,
      'updated_by': ownerId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', prior['id'] as String)
      .eq('revision', revision).select();
    if (rows.length != 1) {
      throw StateError('El diseño cambió en otra sesión. Recarga antes de continuar.');
    }
    return Map<String, dynamic>.from(rows.first);
  }

  Future<void> requestReview(Map<String, dynamic> draft) async {
    await client.from('brand_release_requests').insert({
      'draft_id': draft['id'],
      'revision': draft['revision'],
      'status': 'pending_review',
      'requested_by': ownerId,
    });
  }

  static String? mimeForFile(String name, Uint8List bytes, String kind) {
    if (bytes.length < 12 || bytes.length > (kind == 'font' ? 2097152 : 8388608)) {
      return null;
    }
    final lower = name.toLowerCase();
    final png = bytes[0] == 137 && bytes[1] == 80 &&
        bytes[2] == 78 && bytes[3] == 71;
    final jpeg = bytes[0] == 255 && bytes[1] == 216 &&
        bytes[2] == 255;
    final webp = String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
    final woff2 = String.fromCharCodes(bytes.sublist(0, 4)) == 'wOF2';
    if (kind == 'font') return lower.endsWith('.woff2') && woff2
        ? 'font/woff2' : null;
    if (lower.endsWith('.png') && png) return 'image/png';
    if (lower.endsWith('.webp') && webp) return 'image/webp';
    if (kind != 'logo' &&
        (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) && jpeg) {
      return 'image/jpeg';
    }
    return null;
  }

  Future<Map<String, dynamic>> uploadAsset({
    required String kind,
    required String name,
    required Uint8List bytes,
    String license = 'not_applicable',
  }) async {
    const kinds = ['logo', 'font', 'cover_desktop', 'cover_mobile',
      'login_image', 'onboarding_image', 'app_image', 'icon', 'illustration'];
    if (!kinds.contains(kind)) throw const FormatException('Destino no permitido');
    final mime = mimeForFile(name, bytes, kind);
    if (mime == null) throw const FormatException('Formato o tamaño de archivo no permitido');
    if (kind == 'font' && !const ['owned','open','licensed'].contains(license)) {
      throw const FormatException('Debes declarar la licencia de la fuente');
    }
    final extension = mime == 'font/woff2' ? 'woff2'
        : mime == 'image/png' ? 'png'
        : mime == 'image/webp' ? 'webp' : 'jpg';
    final suffix = Random.secure().nextInt(1 << 32).toRadixString(16)
        .padLeft(8, '0');
    final path = '$ownerId/$kind/'
        '${DateTime.now().microsecondsSinceEpoch}-$suffix.$extension';
    await client.storage.from('mfd-brand-drafts').uploadBinary(path, bytes,
        fileOptions: FileOptions(contentType: mime, upsert: false));
    final rows = await client.from('brand_assets').insert({
      'asset_kind': kind,
      'name': name.substring(0, min(name.length, 100)),
      'storage_path': path,
      'mime_type': mime,
      'bytes': bytes.length,
      'license_basis': kind == 'font' ? license : 'not_applicable',
      'created_by': ownerId,
    }).select();
    if (rows.length != 1) throw StateError('No se pudo registrar el recurso');
    return Map<String, dynamic>.from(rows.first);
  }


  /// B3: the owner selects an image to become PUBLIC. The new immutable copy
  /// is served to all devices with no future build. Private draft files stay
  /// private. AAL2/owner checks are enforced by the storage bucket policy.
  Future<String> uploadPublicBrandAsset({
    required String kind,
    required String name,
    required Uint8List bytes,
  }) async {
    if (!const ['logo','cover_desktop','cover_mobile','app_image'].contains(kind)) {
      throw const FormatException('Solo imágenes públicas aprobadas.');
    }
    if (bytes.length > 4194304) {
      throw const FormatException('Las imágenes públicas admiten máximo 4 MB.');
    }
    final mime = mimeForFile(name,bytes,kind);
    if (mime == null || mime == 'font/woff2') {
      throw const FormatException('Solo PNG, WebP y JPG válidos.');
    }
    final ext = mime == 'image/png' ? 'png'
        : mime == 'image/webp' ? 'webp' : 'jpg';
    final nonce = Random.secure().nextInt(1 << 32).toRadixString(16)
        .padLeft(8, '0');
    final path = '$ownerId/'
        '${DateTime.now().microsecondsSinceEpoch}-$nonce.$ext';
    await client.storage.from('mfd-brand-live').uploadBinary(
      path,bytes,
      fileOptions:FileOptions(contentType:mime,upsert:false),
    );
    final url = client.storage.from('mfd-brand-live').getPublicUrl(path);
    if (!url.startsWith(
      'https://jtrdvnwbxpfdnbzasvcj.supabase.co/storage/v1/object/public/mfd-brand-live/'
    )) {
      throw StateError('Destino de publicación de imagen no confiable.');
    }
    return url;
  }

  Future<Uint8List> loadPrivateAsset(Map<String, dynamic> asset) async {
    final path = asset['storage_path'];
    if (path is! String || !path.startsWith('$ownerId/')) {
      // Other admins can read the catalogue under RLS, but no direct
      // local path should be fabricated by the UI. Asset access is
      // independently enforced by storage policies.
      if (path is! String || path.isEmpty) throw const FormatException('Ruta inválida');
    }
    return client.storage.from('mfd-brand-drafts').download(path);
  }
}
