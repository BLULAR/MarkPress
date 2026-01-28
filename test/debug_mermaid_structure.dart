import 'package:markdown/markdown.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  final file = File(r'c:\DEV\MD_VIEWER_FLU\Workflows 1.md');
  if (!file.existsSync()) {
    print('File not found: ${file.path}');
    return;
  }
  final source = file.readAsStringSync();

  // Parse with GFM
  final document = Document(extensionSet: ExtensionSet.gitHubFlavored);
  final nodes = document.parse(source);

  print('Structure des nœuds:');
  for (final node in nodes) {
    if (node is Element) {
      printNode(node);
    }
  }
}

void printNode(Element element, [String indent = '']) {
  print('$indent<${element.tag} class="${element.attributes['class'] ?? ''}">');
  
  if (element.tag == 'code' && element.attributes['class'] != null && element.attributes['class']!.contains('mermaid')) {
      print('$indent  [MERMAID DETECTED]');
      final text = element.textContent;
      String unescapedCode = text
        .replaceAll('&gt;', '>')
        .replaceAll('&lt;', '<')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
      
      final jsonState = jsonEncode({
        'code': unescapedCode,
        'mermaid': {'theme': 'default'}
      });
      final base64State = base64Encode(utf8.encode(jsonState));
      final url = 'https://mermaid.ink/img/$base64State';
      print('$indent  URL: $url');
  }

  if (element.children != null) {
    for (final child in element.children!) {
      if (child is Element) {
        printNode(child, '$indent  ');
      } else if (child is Text) {
        print('$indent  Text: "${child.text.replaceAll('\n', '\\n')}"');
      }
    }
  }
  print('$indent</${element.tag}>');
}

