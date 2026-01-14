// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MarkPress';

  @override
  String get actionOpen => 'Open Files';

  @override
  String get actionExport => 'Export PDF';

  @override
  String get actionInfo => 'About';

  @override
  String get actionLanguage => 'Language';

  @override
  String get tabWelcome => 'Welcome';

  @override
  String msgSavedTo(Object path) {
    return 'Saved to $path';
  }

  @override
  String msgErrorOpen(Object error) {
    return 'Error opening file: $error';
  }

  @override
  String msgErrorExport(Object error) {
    return 'Error exporting PDF: $error';
  }

  @override
  String labelPath(Object path) {
    return 'Path: $path';
  }

  @override
  String get aboutDev => 'Developed by SergeT';

  @override
  String get aboutDesc =>
      'MarkPress is a modern, lightweight Markdown viewer for desktop. View multiple files in tabs, navigate with ease, and export your documents to high-quality PDFs.';

  @override
  String get welcomeContent =>
      '# Welcome to MarkPress\n\nClick the **folder icon** in the top right to open `.md` files.\n\n## Features\n- **Multi-tabs support**\n- **Export to PDF** (MarkPress engine)\n- **Multi-language** support\n- Simple and fast interface';

  @override
  String get msgCopiedToClipboard => 'Copied to clipboard';
}
