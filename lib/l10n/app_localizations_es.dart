// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MarkPress';

  @override
  String get actionOpen => 'Abrir archivos';

  @override
  String get actionExport => 'Exportar PDF';

  @override
  String get actionInfo => 'Acerca de';

  @override
  String get actionLanguage => 'Idioma';

  @override
  String get tabWelcome => 'Bienvenido';

  @override
  String msgSavedTo(Object path) {
    return 'Guardado en $path';
  }

  @override
  String msgErrorOpen(Object error) {
    return 'Error al abrir: $error';
  }

  @override
  String msgErrorExport(Object error) {
    return 'Error al exportar: $error';
  }

  @override
  String labelPath(Object path) {
    return 'Ruta: $path';
  }

  @override
  String get aboutDev => 'Desarrollado por SergeT';

  @override
  String get aboutDesc =>
      'MarkPress es un visor de Markdown moderno y ligero para escritorio. Vea varios archivos en pestañas, navegue fácilmente y exporte sus documentos a PDF de alta calidad.';

  @override
  String get welcomeContent =>
      '# Bienvenido a MarkPress\n\nHaga clic en el icono de **carpeta** en la parte superior derecha para abrir archivos `.md`.\n\n## Características\n- **Soporte multi-pestaña**\n- **Exportación a PDF** (Motor MarkPress)\n- **Multilenguaje**\n- Interfaz simple y rápida';
}
