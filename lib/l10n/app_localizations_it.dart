// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'MarkPress';

  @override
  String get actionOpen => 'Apri file';

  @override
  String get actionExport => 'Esporta PDF';

  @override
  String get actionInfo => 'Informazioni';

  @override
  String get actionLanguage => 'Lingua';

  @override
  String get tabWelcome => 'Benvenuto';

  @override
  String msgSavedTo(Object path) {
    return 'Salvato in $path';
  }

  @override
  String msgErrorOpen(Object error) {
    return 'Errore durante l apertura: $error';
  }

  @override
  String msgErrorExport(Object error) {
    return 'Errore durante l esportazione: $error';
  }

  @override
  String labelPath(Object path) {
    return 'Percorso: $path';
  }

  @override
  String get aboutDev => 'Sviluppato da SergeT';

  @override
  String get aboutDesc =>
      'MarkPress è un visualizzatore Markdown moderno e leggero per desktop. Visualizza più file in schede, naviga facilmente ed esporta i tuoi documenti in PDF di alta qualità.';

  @override
  String get welcomeContent =>
      '# Benvenuto in MarkPress\n\nClicca sull icona della **cartella** in alto a destra per aprire i file `.md`.\n\n## Caratteristiche\n- **Supporto multi-scheda**\n- **Esportazione PDF** (Motore MarkPress)\n- **Diagrammi Mermaid** integrati\n- **Multilingua**\n- Interfaccia semplice e veloce';

  @override
  String get msgCopiedToClipboard => 'Copiato negli appunti';
}
