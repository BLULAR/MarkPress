// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'MarkPress';

  @override
  String get actionOpen => 'Dateien öffnen';

  @override
  String get actionExport => 'PDF exportieren';

  @override
  String get actionInfo => 'Über';

  @override
  String get actionLanguage => 'Sprache';

  @override
  String get tabWelcome => 'Willkommen';

  @override
  String msgSavedTo(Object path) {
    return 'Gespeichert unter $path';
  }

  @override
  String msgErrorOpen(Object error) {
    return 'Fehler beim Öffnen: $error';
  }

  @override
  String msgErrorExport(Object error) {
    return 'Fehler beim Exportieren: $error';
  }

  @override
  String labelPath(Object path) {
    return 'Pfad: $path';
  }

  @override
  String get aboutDev => 'Entwickelt von SergeT';

  @override
  String get aboutDesc =>
      'MarkPress ist ein moderner, leichter Markdown-Viewer für den Desktop. Betrachten Sie mehrere Dateien in Tabs, navigieren Sie einfach und exportieren Sie Ihre Dokumente in hochwertige PDFs.';

  @override
  String get welcomeContent =>
      '# Willkommen bei MarkPress\n\nKlicken Sie auf das **Ordner-Symbol** oben rechts, um `.md`-Dateien zu öffnen.\n\n## Funktionen\n- **Multi-Tab-Unterstützung**\n- **PDF-Export** (MarkPress-Engine)\n- **Mehrsprachig**\n- Einfache und schnelle Oberfläche';

  @override
  String get msgCopiedToClipboard => 'In die Zwischenablage kopiert';
}
