import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:markdown/markdown.dart' as md;
import 'package:printing/printing.dart';

class PdfExporter {
  static Future<Uint8List> generatePdf(String markdownContent) async {
    final pdf = pw.Document();
    
    // Load fonts
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final fontItalic = await PdfGoogleFonts.notoSansItalic();
    final fontBoldItalic = await PdfGoogleFonts.notoSansBoldItalic();
    final fontMono = await PdfGoogleFonts.robotoMonoRegular();
    final fontEmoji = await PdfGoogleFonts.notoColorEmoji();
    // Use NotoSansSC (Simplified Chinese) as a robust fallback for box drawing chars and symbols
    final fontSymbols = await PdfGoogleFonts.notoSansSCRegular();
    
    // Create a fallback list for special characters
    // Order matters: Emoji -> Symbols/BoxDrawing -> Regular
    final fontFallback = [fontEmoji, fontSymbols, fontRegular];

    final converter = _MarkdownToPdfConverter(
      baseFont: fontRegular,
      boldFont: fontBold,
      italicFont: fontItalic,
      boldItalicFont: fontBoldItalic,
      monoFont: fontMono,
      fontFallback: fontFallback,
    );

    final widgets = converter.convert(markdownContent);

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

  List<pw.Widget> convert(String markdownContent) {
    final List<md.Node> nodes = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored).parse(markdownContent);
    return _parseNodes(nodes);
  }

  List<pw.Widget> _parseNodes(List<md.Node> nodes) {
    final widgets = <pw.Widget>[];

    for (final node in nodes) {
      if (node is md.Element) {
        widgets.addAll(_parseElement(node));
      } else if (node is md.Text) {
        widgets.add(pw.Text(_unescape(node.text), style: pw.TextStyle(fontFallback: fontFallback)));
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
    
    // Check for custom ID pattern {#my-id} using relaxed regex
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

  List<pw.Widget> _parseElement(md.Element element) {
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
        widgets.add(pw.Padding(padding: const pw.EdgeInsets.only(bottom: 10), child: _buildRichText(element)));
        break;
      case 'ul':
      case 'ol':
        widgets.addAll(_buildList(element));
        break;
      case 'code':
      case 'pre':
        widgets.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),

            child: pw.Text(
              _unescape(element.textContent), 
              style: pw.TextStyle(font: monoFont, fontFallback: fontFallback)
            ),
          ),
        );
        widgets.add(pw.SizedBox(height: 10));
        break;
      case 'blockquote':
         widgets.add(
          pw.Container(
            padding: const pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
            decoration: const pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(color: PdfColors.grey400, width: 4)),
            ),
            child: _buildRichText(element, style: pw.TextStyle(color: PdfColors.grey700, fontStyle: pw.FontStyle.italic, fontFallback: fontFallback)),
          ),
        );
        widgets.add(pw.SizedBox(height: 10));
        break;
      case 'table':
        widgets.add(pw.Padding(padding: const pw.EdgeInsets.only(bottom: 10), child: _buildTable(element)));
        break;
      default:
        if (element.children != null && element.children!.isNotEmpty) {
           widgets.addAll(_parseNodes(element.children!));
        }
        break;
    }

    return widgets;
  }

  List<pw.Widget> _buildList(md.Element element) {
    final children = <pw.Widget>[];
    int index = 1;
    final isOrdered = element.tag == 'ol';

    for (final child in element.children ?? []) {
      if (child is md.Element && child.tag == 'li') {
        children.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5, left: 10),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 20,
                  child: pw.Text(isOrdered ? '${index++}.' : '•', style: pw.TextStyle(fontFallback: fontFallback)),
                ),
                pw.Expanded(child: _buildRichText(child)),
              ],
            ),
          ),
        );
      }
    }

    return children;
  }

  pw.Widget _buildRichText(md.Element element, {pw.TextStyle? style}) {
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
            
            final childText = pw.RichText(text: pw.TextSpan(children: childSpans));
            
            pw.Widget widget;
            if (href.startsWith('#')) {
              // Internal link
              widget = pw.Link(destination: _slugify(href.substring(1)), child: childText);
            } else {
              // External link - Security check
              final uri = Uri.tryParse(href);
              final isSafe = uri != null && ['http', 'https', 'mailto'].contains(uri.scheme);
              
              if (isSafe) {
                widget = pw.UrlLink(destination: href, child: childText);
              } else {
                // If unsafe, just render the text without the link
                widget = childText;
              }
            }
            
            spans.add(pw.WidgetSpan(child: widget));
            return; // Skip normal children processing as we handled them
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

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      defaultColumnWidth: const pw.IntrinsicColumnWidth(),
      children: rows,
    );
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
