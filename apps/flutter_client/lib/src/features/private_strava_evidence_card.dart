import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/fitted_locale.dart';
import '../core/private_activity_evidence.dart';
import '../theme/fitness_date_theme.dart';

/// Accessible only in the authenticated owner's profile. This widget never
/// calls Strava's API, MCP, Fit-IA, a backend, or another member's profile.
/// Activities are processed in device memory and immediately discarded.
class PrivateStravaEvidenceCard extends StatefulWidget {
  const PrivateStravaEvidenceCard({super.key, required this.ownerId});
  final String ownerId;

  @override
  State<PrivateStravaEvidenceCard> createState() =>
      _PrivateStravaEvidenceCardState();
}

class _PrivateStravaEvidenceCardState extends State<PrivateStravaEvidenceCard> {
  PrivateActivityEvidence? evidence;
  bool busy = false;
  String? error;

  String get _storageKey => 'fitted_activity_private_v1_' + widget.ownerId;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void didUpdateWidget(covariant PrivateStravaEvidenceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerId != widget.ownerId) {
      evidence = null;
      error = null;
      _restore();
    }
  }

  Future<void> _restore() async {
    if (widget.ownerId.isEmpty) return;
    final owner = widget.ownerId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString('fitted_activity_private_v1_' + owner);
      if (!mounted || widget.ownerId != owner || encoded == null) return;
      setState(() => evidence = decodePrivateEvidence(encoded));
    } catch (_) {
      // A malformed local cache never blocks the user's signed-in profile.
      if (mounted && widget.ownerId == owner) {
        setState(() => error = 'No fue posible recuperar el resumen local.');
      }
    }
  }

  Future<void> _importCsv() async {
    if (busy || widget.ownerId.isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    final owner = widget.ownerId;
    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
        allowMultiple: false,
      );
      if (selection == null) return;
      final file = selection.files.single;
      if (!file.name.toLowerCase().endsWith('.csv')) {
        throw const FormatException('Selecciona el archivo activities.csv.');
      }
      if (file.size > 3 * 1024 * 1024) {
        throw const FormatException('El archivo supera el límite de 3 MB.');
      }
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('No fue posible leer el archivo seleccionado.');
      }
      // Decode and compute locally; do not upload or retain source bytes.
      final parsed = PrivateActivityEvidenceAnalyzer.analyze(
        utf8.decode(bytes),
      );
      if (!mounted || widget.ownerId != owner) return;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || widget.ownerId != owner) return;
      await prefs.setString(_storageKey, encodePrivateEvidence(parsed));
      if (mounted && widget.ownerId == owner) {
        setState(() => evidence = parsed);
      }
    } on FormatException catch (e) {
      if (mounted && widget.ownerId == owner) {
        setState(() => error = e.message);
      }
    } catch (_) {
      if (mounted && widget.ownerId == owner) {
        setState(() => error = 'No fue posible analizar el archivo. Revisa su formato.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _erase() async {
    if (busy || widget.ownerId.isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      if (mounted) setState(() => evidence = null);
    } catch (_) {
      if (mounted) setState(() => error = 'No fue posible borrar el resumen local.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _help() async {
    await launchUrl(
      Uri.parse('https://support.strava.com/es/articles/15401919-como-puedo-exportar-mis-datos-de-strava'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final en = FittedLocaleScope.languageOf(context) == 'en';
    final data = evidence;
    return Card(
      key: const Key('private-strava-evidence-card'),
      child:Padding(
        padding: const EdgeInsets.all(18),
        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Row(children:[
              Icon(Icons.insights_outlined,color:FitDateColors.aqua,size:25),
              const SizedBox(width:10),
              Expanded(child:Text(
                en ? 'What my apps say about me' :
                  'Lo que mis aplicaciones dicen de mí',
                style:Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight:FontWeight.w800),
              )),
              Tooltip(
                message:en ? 'Only you can see this' : 'Visible solo para ti',
                child:Icon(Icons.lock_outline,color:FitDateColors.aqua,size:20),
              ),
            ]),
            const SizedBox(height:7),
            Text(en
              ? 'Strava · private 90-day activity summary'
              : 'Strava · resumen privado de actividad de 90 días',
              style:Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:FitDateColors.muted),
            ),
            const SizedBox(height:12),
            Container(
              padding:const EdgeInsets.all(12),
              decoration:BoxDecoration(
                color:FitDateColors.aqua.withValues(alpha:.08),
                borderRadius:BorderRadius.circular(12),
                border:Border.all(color:FitDateColors.aqua.withValues(alpha:.20))),
              child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Icon(Icons.info_outline,color:FitDateColors.aqua,size:19),
                const SizedBox(width:9),
                Expanded(child:Text(en
                  ? 'Automatic Strava connection is not enabled. For this first test, import activities.csv from your own Strava export. The file stays on this device; no AI service, server or other member receives it.'
                  : 'La conexión automática con Strava no está habilitada. Para esta primera prueba, importa activities.csv de tu propia exportación de Strava. El archivo permanece en este dispositivo; no se envía a IA, servidores ni a otros miembros.',
                  style:Theme.of(context).textTheme.bodySmall)),
              ]),
            ),
            if (data != null) ...[
              const SizedBox(height:16),
              Text(
                en ? data.summaryEn : data.summaryEs,
                key: const Key('private-strava-executive-summary'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height:1.5),
              ),
              const SizedBox(height:10),
              Text(
                en
                  ? 'Last manual import: ' + _date(data.importedAt) +
                      '. No automatic synchronization.'
                  : 'Última importación manual: ' + _date(data.importedAt) +
                      '. Sin sincronización automática.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:FitDateColors.muted),
              ),
            ] else ...[
              const SizedBox(height:14),
              Text(en
                ? 'No imported activities yet. Your private summary will appear here.'
                : 'Todavía no hay actividades importadas. Aquí aparecerá tu resumen privado.',
                style:Theme.of(context).textTheme.bodyMedium),
            ],
            if(error != null) ...[
              const SizedBox(height:10),
              Text(error!,key:const Key('private-strava-import-error'),
                style:TextStyle(color:Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height:14),
            Wrap(spacing:8,runSpacing:8,children:[
              FilledButton.icon(
                key:const Key('private-strava-import-csv'),
                onPressed:busy?null:_importCsv,
                icon:const Icon(Icons.file_upload_outlined),
                label:Text(en?'Import activities.csv':'Importar activities.csv')),
              OutlinedButton.icon(
                onPressed:busy?null:_help,
                icon:const Icon(Icons.help_outline),
                label:Text(en?'How to export':'Cómo exportar')),
              if(data != null) TextButton.icon(
                key:const Key('private-strava-erase'),
                onPressed:busy?null:_erase,
                icon:const Icon(Icons.delete_outline),
                label:Text(en?'Delete my summary':'Eliminar mi resumen')),
            ]),
            const SizedBox(height:10),
            Text(en
              ? 'Stored only on this device, for this signed-in account. This is not an authenticated Strava connection or proof that an activity occurred.'
              : 'Guardado solo en este dispositivo para esta cuenta. No constituye una conexión autenticada con Strava ni prueba de que la actividad ocurrió.',
              style:Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize:11,color:FitDateColors.muted)),
          ],
        ),
      ),
    );
  }

  String _date(DateTime value) =>
      value.year.toString() + '-' +
      value.month.toString().padLeft(2,'0') + '-' +
      value.day.toString().padLeft(2,'0');
}
