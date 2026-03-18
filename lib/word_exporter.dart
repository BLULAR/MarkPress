import 'dart:convert';
import 'dart:typed_data';

import 'package:docx_creator/docx_creator.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:markdown/markdown.dart' as md;

class WordExporter {
  static const double _bodyFontSize = 11;
  static const double _listFontSize = 11;
  static const double _tableFontSize = 10.5;
  static const double _maxMermaidWidth = 460;
  static const double _maxMermaidHeight = 520;

  static Future<Uint8List> generateDocx(String markdownContent) async {
    String processedContent = markdownContent
        .replaceAll('\uFE0F', '')
        .replaceAll('\u200B', '');

    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F000}-\u{1F02F}]',
      unicode: true,
    );
    processedContent = processedContent.replaceAll(emojiRegex, '');

    final elements = await _parseMarkdownBlocks(processedContent);
    final document = DocxBuiltDocument(
      elements: elements,
    );

    final bytes = await DocxExporter().exportToBytes(document);
    return Uint8List.fromList(bytes);
  }

  static Future<List<DocxNode>> _parseMarkdownBlocks(String markdown) async {
    final lines = markdown.split(RegExp(r'\r?\n'));
    final elements = <DocxNode>[];
    final textBuffer = <String>[];
    bool inCodeFence = false;

    Future<void> flushTextBuffer() async {
      if (textBuffer.isEmpty) {
        return;
      }

      final chunk = textBuffer.join('\n').trim();
      textBuffer.clear();

      if (chunk.isEmpty) {
        return;
      }

      final parsed = await MarkdownParser.parse(chunk);
      elements.addAll(_normalizeNodes(parsed));
    }

    int index = 0;
    while (index < lines.length) {
      final currentLine = lines[index];
      final trimmed = currentLine.trim();

      if (trimmed.startsWith('```')) {
        final language = trimmed.substring(3).trim().toLowerCase();

        if (!inCodeFence && language == 'mermaid') {
          await flushTextBuffer();

          final mermaidLines = <String>[];
          index++;
          while (index < lines.length && !lines[index].trim().startsWith('```')) {
            mermaidLines.add(lines[index]);
            index++;
          }

          if (index < lines.length) {
            index++;
          }

          final mermaidBlock = await _buildMermaidBlock(mermaidLines.join('\n').trim());
          if (mermaidBlock != null) {
            elements.add(mermaidBlock);
          } else {
            final fallback = mermaidLines.join('\n').trim();
            if (fallback.isNotEmpty) {
              elements.add(
                DocxParagraph(
                  children: [
                    DocxText(fallback, fontSize: _bodyFontSize),
                  ],
                ),
              );
            }
          }
          continue;
        }

        inCodeFence = !inCodeFence;
        textBuffer.add(currentLine);
        index++;
        continue;
      }

      if (!inCodeFence && _isTableHeader(lines, index)) {
        await flushTextBuffer();

        final tableLines = <String>[lines[index], lines[index + 1]];
        index += 2;

        while (index < lines.length && _isTableRow(lines[index])) {
          tableLines.add(lines[index]);
          index++;
        }

        final table = _buildMarkdownTable(tableLines);
        if (table != null) {
          elements.add(table);
        } else {
          final parsed = await MarkdownParser.parse(tableLines.join('\n'));
          elements.addAll(_normalizeNodes(parsed));
        }
        continue;
      }

      textBuffer.add(currentLine);
      index++;
    }

    await flushTextBuffer();
    return elements;
  }

  static List<DocxNode> _normalizeNodes(List<DocxNode> nodes) {
    return nodes.map(_normalizeNode).toList();
  }

  static DocxNode _normalizeNode(DocxNode node) {
    if (node is DocxParagraph) {
      return node.copyWith(
        children: node.children.map((child) => _normalizeInline(child, _bodyFontSize)).toList(),
      );
    }

    if (node is DocxList) {
      return node.copyWith(
        items: node.items
            .map(
              (item) => DocxListItem(
                item.children.map((child) => _normalizeInline(child, _listFontSize)).toList(),
                level: item.level,
                overrideStyle: item.overrideStyle,
                id: item.id,
              ),
            )
            .toList(),
        isOrdered: node.isOrdered,
        style: node.style,
        startIndex: node.startIndex,
      )..numId = node.numId;
    }

    if (node is DocxTable) {
      return node.copyWith(
        rows: node.rows
            .map(
              (row) => row.copyWith(
                cells: row.cells
                    .map(
                      (cell) => cell.copyWith(
                        children: cell.children
                            .map((child) => _normalizeBlock(child, _tableFontSize))
                            .toList(),
                        shadingFill: cell.shadingFill,
                      ),
                    )
                    .toList(),
                height: row.height,
              ),
            )
            .toList(),
      );
    }

    return node;
  }

  static DocxBlock _normalizeBlock(DocxBlock block, double defaultFontSize) {
    if (block is DocxParagraph) {
      return block.copyWith(
        children: block.children.map((child) => _normalizeInline(child, defaultFontSize)).toList(),
      );
    }

    return block;
  }

  static DocxInline _normalizeInline(DocxInline inline, double defaultFontSize) {
    if (inline is DocxText) {
      return DocxText(
        inline.content,
        fontWeight: inline.fontWeight,
        fontStyle: inline.fontStyle,
        decorations: inline.decorations,
        color: inline.color,
        highlight: inline.highlight,
        shadingFill: inline.shadingFill,
        fontSize: inline.fontSize ?? defaultFontSize,
        themeColor: inline.themeColor,
        themeTint: inline.themeTint,
        themeShade: inline.themeShade,
        themeFill: inline.themeFill,
        themeFillTint: inline.themeFillTint,
        themeFillShade: inline.themeFillShade,
        fontFamily: inline.fontFamily,
        fonts: inline.fonts,
        characterSpacing: inline.characterSpacing,
        href: inline.href,
        isSuperscript: inline.isSuperscript,
        isSubscript: inline.isSubscript,
        isAllCaps: inline.isAllCaps,
        isSmallCaps: inline.isSmallCaps,
        isDoubleStrike: inline.isDoubleStrike,
        isOutline: inline.isOutline,
        isShadow: inline.isShadow,
        isEmboss: inline.isEmboss,
        isImprint: inline.isImprint,
        textBorder: inline.textBorder,
        id: inline.id,
      );
    }

    return inline;
  }

  static Future<DocxNode?> _buildMermaidBlock(String mermaidCode) async {
    if (mermaidCode.isEmpty) {
      return null;
    }

    try {
      final base64Code = base64Url.encode(utf8.encode(mermaidCode));
      final url = Uri.parse('https://mermaid.ink/img/$base64Code');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }

      final decodedImage = img.decodeImage(response.bodyBytes);
      final imageWidth = (decodedImage?.width ?? 1200).toDouble();
      final imageHeight = (decodedImage?.height ?? 800).toDouble();
      final widthScale = _maxMermaidWidth / imageWidth;
      final heightScale = _maxMermaidHeight / imageHeight;
      final scale = [widthScale, heightScale, 1.0].reduce((a, b) => a < b ? a : b);
      final targetWidth = imageWidth * scale;
      final targetHeight = imageHeight * scale;

      return DocxImage(
        bytes: response.bodyBytes,
        extension: 'png',
        width: targetWidth,
        height: targetHeight,
        altText: 'Mermaid diagram',
      );
    } catch (_) {
      return null;
    }
  }

  static bool _isTableHeader(List<String> lines, int index) {
    if (index + 1 >= lines.length) {
      return false;
    }

    return _isTableRow(lines[index]) && _isTableSeparator(lines[index + 1]);
  }

  static bool _isTableRow(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || !trimmed.contains('|')) {
      return false;
    }

    if (trimmed.startsWith('```')) {
      return false;
    }

    final cells = _splitMarkdownTableRow(trimmed);
    return cells.length >= 2;
  }

  static bool _isTableSeparator(String line) {
    final cells = _splitMarkdownTableRow(line.trim());
    if (cells.length < 2) {
      return false;
    }

    return cells.every(
      (cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell.trim()),
    );
  }

  static DocxTable? _buildMarkdownTable(List<String> lines) {
    if (lines.length < 2) {
      return null;
    }

    final headerCells = _splitMarkdownTableRow(lines.first)
        .map(_normalizeCellText)
        .toList();

    if (headerCells.length < 2 || !_isTableSeparator(lines[1])) {
      return null;
    }

    final rows = <DocxTableRow>[
      DocxTableRow(
        cells: headerCells
            .map(
              (cell) => DocxTableCell.rich(
                _parseTableCellInlines(cell, forceBold: true),
                shadingFill: 'E0E0E0',
              ),
            )
            .toList(),
      ),
    ];

    for (final line in lines.skip(2)) {
      final cells = _splitMarkdownTableRow(line)
          .map(_normalizeCellText)
          .toList();

      if (cells.isEmpty) {
        continue;
      }

      while (cells.length < headerCells.length) {
        cells.add('');
      }

      rows.add(
        DocxTableRow(
          cells: cells
              .take(headerCells.length)
              .map(
                (cell) => DocxTableCell.rich(_parseTableCellInlines(cell)),
              )
              .toList(),
        ),
      );
    }

    return DocxTable(
      rows: rows,
      style: DocxTableStyle.grid,
      hasHeader: true,
    );
  }

  static List<String> _splitMarkdownTableRow(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final normalized = trimmed.startsWith('|') ? trimmed.substring(1) : trimmed;
    final content = normalized.endsWith('|')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;

    final cells = <String>[];
    final current = StringBuffer();
    bool escaped = false;

    for (final char in content.split('')) {
      if (escaped) {
        current.write(char);
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      if (char == '|') {
        cells.add(current.toString().trim());
        current.clear();
        continue;
      }

      current.write(char);
    }

    cells.add(current.toString().trim());
    return cells;
  }

  static String _normalizeCellText(String text) {
    return text
        .replaceAll('\\|', '|')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .trim();
  }

  static List<DocxInline> _parseTableCellInlines(String text, {bool forceBold = false}) {
    final normalized = _normalizeCellText(text);
    if (normalized.isEmpty) {
      return const [DocxText('')];
    }

    final document = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);
    final nodes = document.parseInline(normalized);
    final inlines = _convertInlineNodes(nodes, forceBold: forceBold);
    return inlines.isEmpty
        ? [DocxText(normalized, fontSize: _tableFontSize)]
        : inlines;
  }

  static List<DocxInline> _convertInlineNodes(List<md.Node> nodes, {bool forceBold = false}) {
    final result = <DocxInline>[];
    for (final node in nodes) {
      result.addAll(_convertInlineNode(node, forceBold: forceBold));
    }
    return result;
  }

  static List<DocxInline> _convertInlineNode(md.Node node, {bool forceBold = false}) {
    if (node is md.Text) {
      final text = node.text;
      if (text.isEmpty) {
        return const [];
      }
      return [
        DocxText(
          text,
          fontSize: _tableFontSize,
          fontWeight: forceBold ? DocxFontWeight.bold : DocxFontWeight.normal,
        ),
      ];
    }

    if (node is! md.Element) {
      return const [];
    }

    final children = _convertInlineNodes(node.children ?? const [], forceBold: forceBold);

    switch (node.tag) {
      case 'strong':
      case 'b':
        return _applyInlineStyle(children, bold: true);
      case 'em':
      case 'i':
        return _applyInlineStyle(children, italic: true);
      case 'code':
        return [
          DocxText(
            node.textContent,
            fontSize: _tableFontSize,
            fontWeight: forceBold ? DocxFontWeight.bold : DocxFontWeight.normal,
            fontFamily: 'Consolas',
          ),
        ];
      case 'a':
        final href = node.attributes['href'];
        final linkText = children.whereType<DocxText>().map((child) => child.content).join();
        final content = linkText.isEmpty ? node.textContent : linkText;
        return [
          DocxText.link(
            content,
            href: href ?? '#',
            fontSize: _tableFontSize,
          ),
        ];
      case 'br':
        return const [DocxLineBreak()];
      default:
        return children;
    }
  }

  static List<DocxInline> _applyInlineStyle(
    List<DocxInline> inlines, {
    bool bold = false,
    bool italic = false,
  }) {
    return inlines.map((inline) {
      if (inline is! DocxText) {
        return inline;
      }

      final currentBold = inline.fontWeight == DocxFontWeight.bold;
      final currentItalic = inline.fontStyle == DocxFontStyle.italic;

      return DocxText(
        inline.content,
        fontWeight: bold || currentBold ? DocxFontWeight.bold : DocxFontWeight.normal,
        fontStyle: italic || currentItalic ? DocxFontStyle.italic : DocxFontStyle.normal,
        decorations: inline.decorations,
        color: inline.color,
        highlight: inline.highlight,
        shadingFill: inline.shadingFill,
        fontSize: inline.fontSize ?? _tableFontSize,
        themeColor: inline.themeColor,
        themeTint: inline.themeTint,
        themeShade: inline.themeShade,
        themeFill: inline.themeFill,
        themeFillTint: inline.themeFillTint,
        themeFillShade: inline.themeFillShade,
        fontFamily: inline.fontFamily,
        fonts: inline.fonts,
        characterSpacing: inline.characterSpacing,
        href: inline.href,
        isSuperscript: inline.isSuperscript,
        isSubscript: inline.isSubscript,
        isAllCaps: inline.isAllCaps,
        isSmallCaps: inline.isSmallCaps,
        isDoubleStrike: inline.isDoubleStrike,
        isOutline: inline.isOutline,
        isShadow: inline.isShadow,
        isEmboss: inline.isEmboss,
        isImprint: inline.isImprint,
        textBorder: inline.textBorder,
        id: inline.id,
      );
    }).toList();
  }
}
