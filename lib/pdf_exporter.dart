import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:markdown/markdown.dart' as md;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class PdfExporter {
  static Future<Uint8List> generatePdf(String markdownContent) async {
    final pdf = pw.Document();
    
    // 1. Initial Sanitization (Invisible chars)
    String processedContent = markdownContent
        .replaceAll('\uFE0F', '')
        .replaceAll('\u200B', '');

    // 2. Load fonts safely
    pw.Font fontRegular;
    pw.Font fontBold;
    pw.Font fontItalic;
    pw.Font fontBoldItalic;
    pw.Font fontMono;
    pw.Font fontSymbols;
    pw.Font? fontEmoji; // Nullable to track success
    bool emojiLoaded = false;

    try {
      fontRegular = await PdfGoogleFonts.notoSansRegular();
      fontBold = await PdfGoogleFonts.notoSansBold();
      fontItalic = await PdfGoogleFonts.notoSansItalic();
      fontBoldItalic = await PdfGoogleFonts.notoSansBoldItalic();
      fontMono = await PdfGoogleFonts.robotoMonoRegular();
      fontSymbols = await PdfGoogleFonts.notoSansSCRegular();
      
      // Try to load Emojis
      fontEmoji = await PdfGoogleFonts.notoColorEmoji();
      emojiLoaded = true;
    } catch (e) {
      // Fallback for standard text
      fontRegular = pw.Font.times();
      fontBold = pw.Font.timesBold();
      fontItalic = pw.Font.timesItalic();
      fontBoldItalic = pw.Font.timesBoldItalic();
      fontMono = pw.Font.courier();
      fontSymbols = pw.Font.zapfDingbats();
      // emoji remains null
    }

    // 3. Emoji Safety Protocol
    // If we couldn't load the Emoji font, we MUST strip emojis from the text
    // otherwise the PDF engine will crash trying to draw characters it doesn't have glyphs for.
    if (!emojiLoaded || fontEmoji == null) {
      // Regex to remove common emoji ranges (Surrogates, Transport, Symbols, etc.)
      // This is a safety net to prevent "Unable to find font for 🚀" crash
      final emojiRegex = RegExp(r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F000}-\u{1F02F}]', unicode: true);
      processedContent = processedContent.replaceAll(emojiRegex, '');
    }

    // Build font fallback list (filter out nulls)
    final List<pw.Font> fontFallback = [
      if (fontEmoji != null) fontEmoji,
      fontSymbols,
      fontRegular
    ];

    final converter = _MarkdownToPdfConverter(
      baseFont: fontRegular,
      boldFont: fontBold,
      italicFont: fontItalic,
      boldItalicFont: fontBoldItalic,
      monoFont: fontMono,
      fontFallback: fontFallback,
    );

    try {
      final widgets = await converter.convert(processedContent);
  
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
            italic: fontItalic,
            boldItalic: fontBoldItalic,
            fontFallback: fontFallback,
          ),
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return widgets;
          },
        ),
      );
    } catch (e) {
      // Last resort fallback if something goes critically wrong during layout
      pdf.addPage(pw.Page(build: (ctx) => pw.Center(child: pw.Text('Error generating PDF: $e'))));
    }

    return await pdf.save();
  }
}

class _MarkdownToPdfConverter {
  final pw.Font baseFont;
  final pw.Font boldFont;
  final pw.Font italicFont;
  final pw.Font boldItalicFont;
  final pw.Font monoFont;
  final List<pw.Font> fontFallback;

  _MarkdownToPdfConverter({
    required this.baseFont,
    required this.boldFont,
    required this.italicFont,
    required this.boldItalicFont,
    required this.monoFont,
    required this.fontFallback,
  });

  Future<List<pw.Widget>> convert(String markdownContent) async {
    // Enable HTML block parsing to handle <div> etc. better
    final List<md.Node> nodes = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false, 
    ).parse(markdownContent);
    
    return await _parseNodes(nodes);
  }

  Future<List<pw.Widget>> _parseNodes(List<md.Node> nodes) async {
    final widgets = <pw.Widget>[];

    for (final node in nodes) {
      try {
        if (node is md.Element) {
          widgets.addAll(await _parseElement(node));
        } else if (node is md.Text) {
          widgets.add(pw.Text(_unescape(node.text), style: pw.TextStyle(fontFallback: fontFallback)));
        }
      } catch (e) {
        // Safe handling of render errors per block
        widgets.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.red)),
            child: pw.Text('Error rendering block: $e', style: const pw.TextStyle(color: PdfColors.red)),
          )
        );
      }
    }

    return widgets;
  }

  String _slugify(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  }

  pw.Widget _buildHeader(md.Element element, int level, double fontSize) {
    var text = _unescape(element.textContent);
    String id;
    
    final match = RegExp(r'\{#([^}]+)\}\s*$').firstMatch(text);
    if (match != null) {
      final rawId = match.group(1)!.trim();
      id = _slugify(rawId);
      text = text.substring(0, match.start).trim();
    } else {
      id = _slugify(text);
    }
    
    return pw.Anchor(
      name: id,
      child: pw.Header(
        level: level,
        child: pw.Text(text, style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, fontFallback: fontFallback)),
      ),
    );
  }

  Future<List<pw.Widget>> _parseElement(md.Element element) async {
    final widgets = <pw.Widget>[];

    switch (element.tag) {
      case 'h1':
        widgets.add(_buildHeader(element, 0, 24));
        break;
      case 'h2':
        widgets.add(_buildHeader(element, 1, 20));
        break;
      case 'h3':
        widgets.add(_buildHeader(element, 2, 18));
        break;
      case 'h4':
      case 'h5':
      case 'h6':
        widgets.add(_buildHeader(element, 3, 16));
        break;
        
      case 'p':
        widgets.add(_buildRichText(element));
        widgets.add(pw.SizedBox(height: 10));
        break;
        
      case 'ul':
      case 'ol':
        widgets.addAll(_buildList(element));
        break;
        
      case 'code':
      case 'pre':
        final text = _unescape(element.textContent);
        
        // Check for Mermaid diagram
        bool isMermaid = false;
        String mermaidCode = text;
        
        // Check element class
        if (element.attributes.containsKey('class') && 
            element.attributes['class']!.contains('language-mermaid')) {
          isMermaid = true;
        }
        
        // Check children for <code class="language-mermaid">
        if (!isMermaid && element.children != null) {
          for (final child in element.children!) {
            if (child is md.Element && child.tag == 'code') {
              if (child.attributes.containsKey('class') &&
                  child.attributes['class']!.contains('language-mermaid')) {
                isMermaid = true;
                mermaidCode = _unescape(child.textContent);
                break;
              }
            }
          }
        }
        
        if (isMermaid) {
          // Try to fetch and embed Mermaid diagram as image
          try {
            final imageWidget = await _buildMermaidImage(mermaidCode);
            if (imageWidget != null) {
              widgets.add(imageWidget);
              widgets.add(pw.SizedBox(height: 10));
              break;
            }
          } catch (e) {
            // Fall through to code block fallback
          }
          
          // Fallback: Show as styled code block with label
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border.all(color: PdfColors.amber),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Mermaid Diagram (requires network)', 
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.amber900, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(mermaidCode, 
                    style: pw.TextStyle(font: monoFont, fontFallback: fontFallback, fontSize: 8)),
                ],
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 10));
          break;
        }
        
        // Standard code block
        final lines = text.split('\n');
        const int chunkSize = 40;
        for (int i = 0; i < lines.length; i += chunkSize) {
          final end = (i + chunkSize < lines.length) ? i + chunkSize : lines.length;
          final chunkLines = lines.sublist(i, end);
          final chunkText = chunkLines.join('\n');
          
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              color: PdfColors.grey100,
              width: double.infinity,
              child: pw.Text(
                chunkText, 
                style: pw.TextStyle(font: monoFont, fontFallback: fontFallback, fontSize: 10),
              ),
            )
          );
        }
        widgets.add(pw.SizedBox(height: 10));
        break;
        
      case 'blockquote':
         widgets.add(
           pw.Padding(
             padding: const pw.EdgeInsets.only(left: 16, top: 8, bottom: 8),
             child: pw.Container(
               decoration: const pw.BoxDecoration(
                 border: pw.Border(left: pw.BorderSide(color: PdfColors.grey400, width: 2))
               ),
               padding: const pw.EdgeInsets.only(left: 8),
               child: _buildRichText(element, style: pw.TextStyle(color: PdfColors.grey700, fontStyle: pw.FontStyle.italic, fontFallback: fontFallback)),
             ),
           )
         );
        widgets.add(pw.SizedBox(height: 10));
        break;
        
      case 'table':
        widgets.add(_buildTable(element));
        widgets.add(pw.SizedBox(height: 10));
        break;
      
      case 'hr':
        widgets.add(pw.Divider());
        break;

      default:
        // Handle div, section, etc. simply by parsing children
        if (element.children != null && element.children!.isNotEmpty) {
           widgets.addAll(await _parseNodes(element.children!));
        }
        break;
    }

    return widgets;
  }
  
  /// Fetch Mermaid diagram as PNG from mermaid.ink and return as pw.Image
  Future<pw.Widget?> _buildMermaidImage(String mermaidCode) async {
    try {
      // Build URL using simple base64 encoding (same as main.dart)
      final base64Code = base64Url.encode(utf8.encode(mermaidCode));
      final url = 'https://mermaid.ink/img/$base64Code';
      
      // Fetch image with timeout
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout fetching diagram'),
      );
      
      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        final image = pw.MemoryImage(imageBytes);
        
        return pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        );
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  List<pw.Widget> _buildList(md.Element element) {
    final children = <pw.Widget>[];
    int index = 1;
    final isOrdered = element.tag == 'ol';

    for (final child in element.children ?? []) {
      if (child is md.Element && child.tag == 'li') {
        // FIX: Replaced Table/Row with Partitions
        // Partitions is a SpanningWidget that allows columns to split across pages.
        // This prevents crashes on very long list items.
        children.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5, left: 10),
            child: pw.Partitions(
              children: [
                pw.Partition(
                  width: 20,
                  child: pw.RichText(text: pw.TextSpan(text: isOrdered ? '${index++}.' : '•', style: pw.TextStyle(fontFallback: fontFallback))),
                ),
                pw.Partition(
                  child: _buildRichText(child),
                )
              ]
            ),
          ),
        );
      }
    }

    return children;
  }

  pw.SpanningWidget _buildRichText(md.Element element, {pw.TextStyle? style}) {
    final spans = <pw.InlineSpan>[];
    _parseInline(element, spans, style);
    return pw.RichText(text: pw.TextSpan(children: spans));
  }

  void _parseInline(md.Node node, List<pw.InlineSpan> spans, pw.TextStyle? baseStyle) {
    if (node is md.Text) {
      spans.add(pw.TextSpan(text: _unescape(node.text), style: baseStyle ?? pw.TextStyle(fontFallback: fontFallback)));
    } else if (node is md.Element) {
      pw.TextStyle newStyle = baseStyle ?? pw.TextStyle(fontFallback: fontFallback);

      switch (node.tag) {
        case 'strong':
        case 'b':
          newStyle = newStyle.copyWith(fontWeight: pw.FontWeight.bold);
          break;
        case 'em':
        case 'i':
          newStyle = newStyle.copyWith(fontStyle: pw.FontStyle.italic);
          break;
        case 'code':
          newStyle = newStyle.copyWith(font: monoFont, background: const pw.BoxDecoration(color: PdfColors.grey200));
          break;
        case 'br':
           spans.add(const pw.TextSpan(text: '\n'));
           return; // No children processing for br
        case 'img':
          final alt = node.attributes['alt'] ?? 'Image';
          // Placeholder for images since we can't async load them easily here
          // This prevents empty links and provides visual feedback
          spans.add(
            pw.WidgetSpan(
              baseline: -2,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                margin: const pw.EdgeInsets.symmetric(horizontal: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                     pw.Text('[IMG] ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600, fontFallback: fontFallback)),
                     pw.Text(alt.isNotEmpty ? alt : '...', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic, fontFallback: fontFallback)),
                  ]
                )
              ),
            ),
          );
          return; // No children for img
          
        case 'a':
          newStyle = newStyle.copyWith(color: PdfColors.blue, decoration: pw.TextDecoration.underline);
          final href = node.attributes['href'];
          if (href != null) {
            final childSpans = <pw.InlineSpan>[];
            if (node.children != null) {
              for (final child in node.children!) {
                _parseInline(child, childSpans, newStyle);
              }
            }
            
            // If link content is empty (e.g. was an image that failed to parse before), 
            // put the URL or a placeholder so it's clickable
            if (childSpans.isEmpty) {
                 childSpans.add(pw.TextSpan(text: href, style: newStyle));
            }
            
            final childText = pw.RichText(text: pw.TextSpan(children: childSpans));
            
            pw.Widget widget;
            if (href.startsWith('#')) {
              widget = pw.Link(destination: _slugify(href.substring(1)), child: childText);
            } else {
              final uri = Uri.tryParse(href);
              final isSafe = uri != null && ['http', 'https', 'mailto'].contains(uri.scheme);
              
              if (isSafe) {
                widget = pw.UrlLink(destination: href, child: childText);
              } else {
                widget = childText;
              }
            }
            
            spans.add(pw.WidgetSpan(child: widget));
            return;
          }
          break;
      }
      
      if (node.children != null) {
        for (final child in node.children!) {
          _parseInline(child, spans, newStyle);
        }
      }
    }
  }

  pw.Widget _buildTable(md.Element element) {
    try {
      final rows = <pw.TableRow>[];

      void addRow(md.Element row, {bool isHeader = false}) {
        rows.add(_buildTableRow(row, isHeader: isHeader, rowIndex: rows.length));
      }

      for (final child in element.children ?? []) {
        if (child is md.Element) {
          if (child.tag == 'thead') {
            for (final row in child.children ?? []) {
              if (row is md.Element && row.tag == 'tr') {
                addRow(row, isHeader: true);
              }
            }
          } else if (child.tag == 'tbody') {
            for (final row in child.children ?? []) {
              if (row is md.Element && row.tag == 'tr') {
                addRow(row, isHeader: false);
              }
            }
          } else if (child.tag == 'tr') {
            addRow(child, isHeader: false);
          }
        }
      }

      if (rows.isEmpty) return pw.Container();

      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: rows,
      );
    } catch (e) {
      return pw.Text('Table rendering error: $e', style: const pw.TextStyle(color: PdfColors.red));
    }
  }

  pw.TableRow _buildTableRow(md.Element row, {bool isHeader = false, required int rowIndex}) {
    final cells = <pw.Widget>[];
    for (final cell in row.children ?? []) {
      if (cell is md.Element && (cell.tag == 'td' || cell.tag == 'th')) {
        cells.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            color: isHeader
                ? PdfColors.grey300
                : (rowIndex % 2 == 1 ? PdfColors.grey100 : null),
            child: _buildRichText(
              cell,
              style: isHeader ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontFallback: fontFallback) : null,
            ),
          ),
        );
      }
    }
    return pw.TableRow(
      children: cells,
    );
  }

  String _unescape(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'");
  }
}
