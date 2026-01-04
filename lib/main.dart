import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'pdf_exporter.dart';

void main() {
  runApp(const MarkPressApp());
}

class MarkdownFile {
  String name;
  String content;
  final String? path;

  MarkdownFile({required this.name, required this.content, this.path});
}

class MarkPressApp extends StatefulWidget {
  const MarkPressApp({super.key});

  @override
  State<MarkPressApp> createState() => _MarkPressAppState();
}

class _MarkPressAppState extends State<MarkPressApp> {
  Locale? _locale;
  bool _isLanguageLoaded = false;
  static const String _prefLanguageKey = 'selected_language';

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_prefLanguageKey);
    if (mounted) {
      setState(() {
        if (languageCode != null) {
          _locale = Locale(languageCode);
        }
        _isLanguageLoaded = true;
      });
    }
  }

  Future<void> _changeLanguage(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLanguageKey, locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    // Show a simple loading screen until language prefs are loaded
    // This prevents the "flash" of default language content
    if (!_isLanguageLoaded) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'MarkPress',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('fr'), // French
        Locale('de'), // German
        Locale('it'), // Italian
        Locale('es'), // Spanish
      ],
      locale: _locale,
      theme: FlexThemeData.light(
        scheme: FlexScheme.brandBlue,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
        fontFamily: GoogleFonts.notoSans().fontFamily,
      ),
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.brandBlue,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 13,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
        fontFamily: GoogleFonts.notoSans().fontFamily,
      ),
      themeMode: ThemeMode.system,
      home: ViewerPage(onLanguageChanged: _changeLanguage),
    );
  }
}

class ViewerPage extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  const ViewerPage({super.key, required this.onLanguageChanged});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> with TickerProviderStateMixin {
  bool _isLoading = false;
  final Map<String, GlobalKey> _anchors = {};
  
  final List<MarkdownFile> _openedFiles = [];
  int _activeTabIndex = 0;
  late TabController _tabController;
  
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final l10n = AppLocalizations.of(context)!;
    
    if (!_isInit) {
      // First initialization
      _openedFiles.add(MarkdownFile(name: l10n.tabWelcome, content: l10n.welcomeContent));
      _tabController = TabController(length: _openedFiles.length, vsync: this);
      _isInit = true;
    } else {
      // Update welcome tab content if language changed
      // We identify the welcome tab as the one with null path
      for (var file in _openedFiles) {
        if (file.path == null) {
          file.name = l10n.tabWelcome;
          // We assume if it's the internal welcome file, we update the content too
          // (unless user modified it, but currently it's read-only)
          file.content = l10n.welcomeContent;
        }
      }
      // Force UI rebuild to reflect text changes
      setState(() {}); 
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateTabController() {
    // ignore: unused_local_variable
    final oldIndex = _tabController.index;
    _tabController.dispose();
    _tabController = TabController(
      length: _openedFiles.length, 
      vsync: this,
      initialIndex: _activeTabIndex.clamp(0, _openedFiles.length - 1),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _activeTabIndex = _tabController.index;
        });
      }
    });
  }

  void _closeTab(int index) {
    setState(() {
      _openedFiles.removeAt(index);
      if (_openedFiles.isEmpty) {
        final l10n = AppLocalizations.of(context)!;
        _openedFiles.add(MarkdownFile(name: l10n.tabWelcome, content: l10n.welcomeContent));
      }
      _activeTabIndex = _activeTabIndex.clamp(0, _openedFiles.length - 1);
      _updateTabController();
    });
  }

  String _slugify(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'txt'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _isLoading = true;
        });
        
        for (var platformFile in result.files) {
          File file = File(platformFile.path!);
          String content = await file.readAsString();
          
          String fileName = platformFile.name;
          if (fileName.contains('.')) {
            fileName = fileName.substring(0, fileName.lastIndexOf('.'));
          }

          _openedFiles.add(MarkdownFile(
            name: fileName, 
            content: content,
            path: platformFile.path,
          ));
        }

        if (mounted) {
          setState(() {
            _activeTabIndex = _openedFiles.length - 1;
            _isLoading = false;
            _updateTabController();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.msgErrorOpen(e.toString()))),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    final currentFile = _openedFiles[_activeTabIndex];
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: '${currentFile.name}.pdf',
        allowedExtensions: ['pdf'],
        type: FileType.custom,
      );

      if (outputFile == null) return;

      setState(() {
        _isLoading = true;
      });

      final pdfBytes = await PdfExporter.generatePdf(currentFile.content);
      final file = File(outputFile);
      await file.writeAsBytes(pdfBytes);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.msgSavedTo(outputFile)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.msgErrorExport(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _anchors.clear();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    // Safety check
    if (_openedFiles.isEmpty) {
        _openedFiles.add(MarkdownFile(name: l10n.tabWelcome, content: l10n.welcomeContent));
        _updateTabController();
    }
    _activeTabIndex = _activeTabIndex.clamp(0, _openedFiles.length - 1);
    final currentFile = _openedFiles[_activeTabIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.appTitle,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            tooltip: l10n.actionLanguage,
            onSelected: widget.onLanguageChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(value: Locale('en'), child: Text('English')),
              const PopupMenuItem(value: Locale('fr'), child: Text('Français')),
              const PopupMenuItem(value: Locale('de'), child: Text('Deutsch')),
              const PopupMenuItem(value: Locale('it'), child: Text('Italiano')),
              const PopupMenuItem(value: Locale('es'), child: Text('Español')),
            ],
          ).animate().fadeIn(delay: 50.ms).scale(),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: l10n.actionInfo,
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: l10n.appTitle,
                applicationVersion: '1.0.0+1',
                applicationIcon: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'logo/mdviewer32x32.jpg',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                children: [
                  const SizedBox(height: 16),
                  Text(l10n.aboutDev, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(l10n.aboutDesc),
                ],
              );
            },
          ).animate().fadeIn(delay: 100.ms).scale(),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: l10n.actionExport,
            onPressed: _exportPdf,
          ).animate().fadeIn(delay: 200.ms).scale(),
          IconButton(
            icon: const Icon(Icons.file_open_outlined),
            tooltip: l10n.actionOpen,
            onPressed: _pickFile,
          ).animate().fadeIn(delay: 400.ms).scale(),
          const SizedBox(width: 8),
        ],
        bottom: (_openedFiles.length > 1 || (_openedFiles.isNotEmpty && _openedFiles.first.path != null)) ? PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: _openedFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(file.name),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _closeTab(index),
                        child: const Icon(Icons.close, size: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ) : null,
      ),
      body: _isLoading 
        ? Center(
            child: const CircularProgressIndicator()
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1200.ms, color: theme.colorScheme.primaryContainer)
          )
        : Column(
            children: [
              if (currentFile.path != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  child: Text(
                    l10n.labelPath(currentFile.path!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().slideY(begin: -1, end: 0),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _openedFiles.map((file) {
                    return Markdown(
                      // Using locale in the key forces rebuild when language changes
                      key: ValueKey(file.name + file.content.length.toString() + l10n.localeName),
                      data: file.content,
                      selectable: false,
                      builders: {
                        'h1': _HeaderBuilder(_anchors, _slugify, theme.textTheme.headlineMedium?.copyWith(fontFamily: GoogleFonts.poppins().fontFamily)),
                        'h2': _HeaderBuilder(_anchors, _slugify, theme.textTheme.titleLarge?.copyWith(fontFamily: GoogleFonts.poppins().fontFamily)),
                        'h3': _HeaderBuilder(_anchors, _slugify, theme.textTheme.titleMedium?.copyWith(fontFamily: GoogleFonts.poppins().fontFamily)),
                      },
                      onTapLink: (text, href, title) async {
                        if (href != null) {
                          if (href.startsWith('#')) {
                            final slug = _slugify(href.substring(1));
                            final key = _anchors[slug];
                            if (key != null && key.currentContext != null) {
                              Scrollable.ensureVisible(
                                key.currentContext!,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                              );
                            }
                            return;
                          }
                          final Uri? url = Uri.tryParse(href);
                          if (url != null && ['http', 'https', 'mailto'].contains(url.scheme)) {
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          }
                        }
                      },
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        h1: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                        h1Padding: const EdgeInsets.only(top: 16, bottom: 8),
                        h2Padding: const EdgeInsets.only(top: 12, bottom: 4),
                        p: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(color: theme.colorScheme.primary, width: 4),
                          ),
                        ),
                        code: GoogleFonts.firaCode(
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms);
                  }).toList(),
                ),
              ),
            ],
          ),
    );
  }
}

class _HeaderBuilder extends MarkdownElementBuilder {
  final Map<String, GlobalKey> anchors;
  final String Function(String) slugify;
  final TextStyle? textStyle;

  _HeaderBuilder(this.anchors, this.slugify, this.textStyle);

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    var content = text.text;
    String id;
    
    final match = RegExp(r'\{#([^}]+)\}\s*$').firstMatch(content);
    if (match != null) {
      final rawId = match.group(1)!.trim();
      id = slugify(rawId); 
      content = content.substring(0, match.start).trim();
    } else {
      id = slugify(content);
    }
    
    final key = GlobalKey(); 
    anchors[id] = key;
    
    return Text(
      content,
      key: key,
      style: textStyle ?? preferredStyle,
    );
  }
}
