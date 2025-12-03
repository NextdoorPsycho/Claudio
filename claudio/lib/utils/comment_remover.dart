import '../models/language_config.dart';

/// Utility class for removing comments from source code
class CommentRemover {
  /// Remove comments based on the comment style
  static String removeComments(String content, CommentStyle style) {
    switch (style) {
      case CommentStyle.cStyle:
        return _removeCStyleComments(content);
      case CommentStyle.pythonStyle:
        return _removePythonStyleComments(content);
      case CommentStyle.hashStyle:
        return _removeHashStyleComments(content);
      case CommentStyle.htmlStyle:
        return _removeHtmlStyleComments(content);
      case CommentStyle.mixedWeb:
        return _removeMixedWebComments(content);
    }
  }

  /// Remove C-style comments (// and /* */)
  /// Used by: Dart, JavaScript, TypeScript, Java, Kotlin, Go, Rust, C/C++, Swift, C#, PHP
  static String _removeCStyleComments(String content) {
    // First remove multi-line comments (including nested)
    String result = _removeBlockComments(content, '/*', '*/');

    // Then remove single-line comments
    result = _removeSingleLineComments(result, '//');

    // Remove empty lines
    result = _removeEmptyLines(result);

    return result;
  }

  /// Remove Python-style comments (# and """ """)
  static String _removePythonStyleComments(String content) {
    // Remove docstrings (triple quotes)
    String result = content;

    // Remove """ docstrings
    result = result.replaceAll(
      RegExp(r'"""[\s\S]*?"""', multiLine: true),
      '',
    );

    // Remove ''' docstrings
    result = result.replaceAll(
      RegExp(r"'''[\s\S]*?'''", multiLine: true),
      '',
    );

    // Remove # comments
    result = _removeSingleLineComments(result, '#');

    // Remove empty lines
    result = _removeEmptyLines(result);

    return result;
  }

  /// Remove hash-style comments (# only)
  /// Used by: Ruby, Shell, YAML, TOML, etc.
  static String _removeHashStyleComments(String content) {
    String result = _removeSingleLineComments(content, '#');
    result = _removeEmptyLines(result);
    return result;
  }

  /// Remove HTML-style comments (<!-- -->)
  static String _removeHtmlStyleComments(String content) {
    String result = content.replaceAll(
      RegExp(r'<!--[\s\S]*?-->', multiLine: true),
      '',
    );
    result = _removeEmptyLines(result);
    return result;
  }

  /// Remove mixed web comments (HTML, CSS, and JS)
  static String _removeMixedWebComments(String content) {
    String result = content;

    // Remove HTML comments
    result = result.replaceAll(
      RegExp(r'<!--[\s\S]*?-->', multiLine: true),
      '',
    );

    // Remove CSS comments (/* */)
    result = _removeBlockComments(result, '/*', '*/');

    // Remove JS comments (//)
    result = _removeSingleLineComments(result, '//');

    result = _removeEmptyLines(result);
    return result;
  }

  /// Remove block comments with custom delimiters
  static String _removeBlockComments(String content, String start, String end) {
    String result = content;
    int previousLength = -1;

    // Handle nested block comments by processing iteratively
    while (result.length != previousLength) {
      previousLength = result.length;

      // Escape special regex characters
      final startEscaped = RegExp.escape(start);
      final endEscaped = RegExp.escape(end);

      // Non-greedy match
      result = result.replaceAll(
        RegExp('$startEscaped[\\s\\S]*?$endEscaped', multiLine: true),
        '',
      );
    }

    return result;
  }

  /// Remove single-line comments with custom prefix
  static String _removeSingleLineComments(String content, String prefix) {
    final lines = content.split('\n');
    final result = <String>[];

    for (String line in lines) {
      // Check if the entire line is a comment
      final trimmed = line.trimLeft();
      if (trimmed.startsWith(prefix)) {
        // Skip pure comment lines
        continue;
      }

      // Handle inline comments - but be careful with strings
      line = _removeInlineComment(line, prefix);

      result.add(line);
    }

    return result.join('\n');
  }

  /// Remove inline comment from a line, being careful about strings
  static String _removeInlineComment(String line, String prefix) {
    // Track whether we're inside a string
    bool inString = false;
    String stringChar = '';
    bool escaped = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      // Handle string boundaries
      if (!inString && (char == '"' || char == "'" || char == '`')) {
        inString = true;
        stringChar = char;
        continue;
      }

      if (inString && char == stringChar) {
        inString = false;
        continue;
      }

      // Check for comment start (only if not in string)
      if (!inString && line.substring(i).startsWith(prefix)) {
        // Found a comment, return everything before it
        return line.substring(0, i).trimRight();
      }
    }

    return line;
  }

  /// Remove empty lines and lines with only whitespace
  static String _removeEmptyLines(String content) {
    final List<String> lines = content.split('\n');
    final List<String> result = <String>[];
    bool previousWasEmpty = true; // Start as true to remove leading empty lines

    for (final line in lines) {
      final isEmpty = line.trim().isEmpty;

      // Skip consecutive empty lines
      if (isEmpty && previousWasEmpty) {
        continue;
      }

      // Keep the line
      result.add(line);
      previousWasEmpty = isEmpty;
    }

    // Remove trailing empty lines
    while (result.isNotEmpty && result.last.trim().isEmpty) {
      result.removeLast();
    }

    return result.join('\n');
  }

  /// Remove only doc comments while preserving regular comments
  /// Works for C-style (///) and Python-style (""")
  static String removeDocComments(String content, CommentStyle style) {
    switch (style) {
      case CommentStyle.cStyle:
        final lines = content.split('\n');
        final result = <String>[];
        for (final line in lines) {
          final trimmed = line.trimLeft();
          if (trimmed.startsWith('///')) {
            continue;
          }
          result.add(line);
        }
        return result.join('\n');

      case CommentStyle.pythonStyle:
        String result = content;
        result = result.replaceAll(RegExp(r'"""[\s\S]*?"""', multiLine: true), '');
        result = result.replaceAll(RegExp(r"'''[\s\S]*?'''", multiLine: true), '');
        return result;

      default:
        return content;
    }
  }
}
