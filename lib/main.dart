import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'pdf_exporter.dart';

void main() {
  runApp(const MarkdownViewerApp());
}

class MarkdownViewerApp extends StatelessWidget {
  const MarkdownViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Markdown Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ViewerPage(),
    );
  }
}

class ViewerPage extends StatefulWidget {
  const ViewerPage({super.key});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  bool _isLoading = false;
  final Map<String, GlobalKey> _anchors = {};
  
  static const String _defaultContent = '''
# Welcome to Markdown Viewer

Click the **folder icon** in the top right to open a `.md` file.

## Features
- Read-only view
- Supports standard Markdown
- Simple interface
''';

  String _currentFileName = 'markdown_export';
  String _markdownData = _defaultContent;

  void _closeFile() {
    setState(() {
      _markdownData = _defaultContent;
      _currentFileName = 'markdown_export';
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
      );

      if (result != null) {
        setState(() {
          _isLoading = true;
        });
        
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        
        // Extract filename without extension
        String fileName = file.uri.pathSegments.last;
        if (fileName.contains('.')) {
          fileName = fileName.substring(0, fileName.lastIndexOf('.'));
        }

        if (mounted) {
          setState(() {
            _markdownData = content;
            _currentFileName = fileName;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: '$_currentFileName.pdf',
        allowedExtensions: ['pdf'],
        type: FileType.custom,
      );

      if (outputFile == null) {
        // User canceled the picker
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final pdfBytes = await PdfExporter.generatePdf(_markdownData);
      final file = File(outputFile);
      await file.writeAsBytes(pdfBytes);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to $outputFile')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _anchors.clear();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Viewer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Export to PDF',
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Open File',
            onPressed: _pickFile,
          ),
          if (_currentFileName != 'markdown_export')
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close File',
              onPressed: _closeFile,
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Markdown(
            data: _markdownData,
            selectable: false, // Disable selection to ensure links are clickable
            builders: {
              'h1': _HeaderBuilder(_anchors, _slugify, Theme.of(context).textTheme.headlineMedium),
              'h2': _HeaderBuilder(_anchors, _slugify, Theme.of(context).textTheme.titleLarge),
              'h3': _HeaderBuilder(_anchors, _slugify, Theme.of(context).textTheme.titleMedium),
            },
            onTapLink: (text, href, title) async {
              debugPrint('onTapLink: text=$text, href=$href');
              if (href != null) {
                if (href.startsWith('#')) {
                  // Normalize the slug to match our anchor keys
                  final slug = _slugify(href.substring(1));
                  final key = _anchors[slug];
                  debugPrint('Internal link: slug=$slug, key=$key, mounted=${key?.currentContext != null}');
                  if (key != null && key.currentContext != null) {
                    Scrollable.ensureVisible(
                      key.currentContext!,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    debugPrint('Anchor not found for slug: $slug. Available anchors: ${_anchors.keys.join(", ")}');
                  }
                  return;
                }
                final Uri? url = Uri.tryParse(href);
                if (url == null) {
                  debugPrint('Invalid URL: $href');
                  return;
                }
                
                // Security check: Only allow safe schemes
                if (!['http', 'https', 'mailto'].contains(url.scheme)) {
                  debugPrint('Blocked potentially unsafe URL scheme: ${url.scheme}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Blocked unsafe link: $href')),
                  );
                  return;
                }

                debugPrint('External link: url=$url');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  debugPrint('Could not launch url: $url');
                }
              }
            },
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          h1: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          p: Theme.of(context).textTheme.bodyLarge,
        ),
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
    
    // Debug print to see what we are parsing
    // debugPrint('HeaderBuilder visitText: "$content" (codeUnits: ${content.codeUnits})');

    // Check for custom ID pattern {#my-id}
    // Relaxed regex to capture anything inside {#...}
    final match = RegExp(r'\{#([^}]+)\}\s*$').firstMatch(content);
    if (match != null) {
      // Extract ID and strip it from content
      final rawId = match.group(1)!.trim();
      id = slugify(rawId); 
      content = content.substring(0, match.start).trim();
      debugPrint('Found custom anchor: "$rawId" -> "$id" in header');
    } else {
      id = slugify(content);
      // debugPrint('Generated slug: "$id" from "$content"');
    }
    
    // Create and register key
    final key = GlobalKey(); 
    anchors[id] = key;
    
    return Text(
      content,
      key: key,
      style: textStyle ?? preferredStyle,
    );
  }
}
