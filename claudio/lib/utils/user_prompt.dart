import 'dart:io';
import 'package:fast_log/fast_log.dart';

import '../models/gen_config.dart';

/// Utility class for interactive user prompts
class UserPrompt {
  /// Show configuration preview and ask for confirmation
  static Future<bool> confirmConfiguration(GenConfig config) async {
    printConfigPreview(config);

    stdout.write('\nProceed with these settings? [Y/n]: ');

    final input = stdin.readLineSync()?.trim().toLowerCase();

    // Default to yes if empty or 'y' or 'yes'
    return input == null || input.isEmpty || input == 'y' || input == 'yes';
  }

  /// Print a pretty configuration preview box
  static void printConfigPreview(GenConfig config) {
    const int width = 50;
    final line = '\u2500' * width;

    print('');
    print('\u256d$line\u256e');
    _printBoxLine('Configuration Preview', width, center: true);
    print('\u251c$line\u2524');
    _printBoxLine('Project Type:  ${config.projectTypeName}', width);
    _printBoxLine('Source:        ${config.sourceDir}', width);
    _printBoxLine('Output Prefix: ${config.outputPrefix}', width);
    _printBoxLine('Max Size:      ${config.targetSizeKB} KB', width);
    _printBoxLine('Format:        ${config.outputFormatName}', width);
    _printBoxLine('Comments:      ${config.removeComments ? "Removed" : "Kept"}', width);

    // Show file extensions
    print('\u251c$line\u2524');
    final exts = config.effectiveExtensions.join(', ');
    _printBoxLine('Extensions:    $exts', width);

    if (config.verbose) {
      _printBoxLine('Verbose:       Yes', width);
    }

    // Show ignore patterns (compact)
    final patterns = config.effectiveIgnorePatterns;
    if (patterns.isNotEmpty) {
      print('\u251c$line\u2524');
      _printBoxLine('Ignore Patterns: (${patterns.length})', width);
      for (final pattern in patterns.take(3)) {
        _printBoxLine('  \u2022 $pattern', width);
      }
      if (patterns.length > 3) {
        _printBoxLine('  ... and ${patterns.length - 3} more', width);
      }
    }

    if (config.extraRootFiles.isNotEmpty) {
      print('\u251c$line\u2524');
      _printBoxLine('Extra Root Files:', width);
      for (final file in config.extraRootFiles.take(3)) {
        _printBoxLine('  \u2022 $file', width);
      }
      if (config.extraRootFiles.length > 3) {
        _printBoxLine('  ... and ${config.extraRootFiles.length - 3} more', width);
      }
    }

    print('\u2570$line\u256f');
  }

  static void _printBoxLine(String text, int width, {bool center = false}) {
    String content;
    if (center) {
      final padding = (width - text.length) ~/ 2;
      content = ' ' * padding + text + ' ' * (width - padding - text.length);
    } else {
      content = text.length > width ? text.substring(0, width) : text.padRight(width);
    }
    print('\u2502 $content \u2502');
  }

  /// Show progress during file processing
  static void showProgress(int current, int total, String currentFile) {
    final percent = (current / total * 100).toStringAsFixed(0);
    final bar = _makeProgressBar(current, total, 30);

    // Use carriage return to overwrite the line
    stdout.write('\r[$bar] $percent% ($current/$total) $currentFile'.padRight(100));

    // If complete, move to next line
    if (current == total) {
      print('');
    }
  }

  static String _makeProgressBar(int current, int total, int width) {
    final filled = (current / total * width).round();
    final empty = width - filled;
    return '\u2588' * filled + '\u2591' * empty;
  }

  /// Ask a yes/no question
  static Future<bool> askYesNo(String question, {bool defaultValue = true}) async {
    final defaultHint = defaultValue ? '[Y/n]' : '[y/N]';
    stdout.write('$question $defaultHint: ');

    final input = stdin.readLineSync()?.trim().toLowerCase();

    if (input == null || input.isEmpty) {
      return defaultValue;
    }

    return input == 'y' || input == 'yes';
  }

  /// Ask for a string input
  static Future<String> askString(String question, {String? defaultValue}) async {
    if (defaultValue != null) {
      stdout.write('$question [$defaultValue]: ');
    } else {
      stdout.write('$question: ');
    }

    final input = stdin.readLineSync()?.trim();

    if (input == null || input.isEmpty) {
      return defaultValue ?? '';
    }

    return input;
  }

  /// Ask for a number input
  static Future<int> askInt(String question, {required int defaultValue}) async {
    stdout.write('$question [$defaultValue]: ');

    final input = stdin.readLineSync()?.trim();

    if (input == null || input.isEmpty) {
      return defaultValue;
    }

    return int.tryParse(input) ?? defaultValue;
  }

  /// Show a menu and get user selection
  static Future<int> showMenu(String title, List<String> options) async {
    print('\n$title');
    print('\u2500' * 40);

    for (int i = 0; i < options.length; i++) {
      print('  ${i + 1}. ${options[i]}');
    }

    print('\u2500' * 40);
    stdout.write('Enter selection (1-${options.length}): ');

    final input = stdin.readLineSync()?.trim();
    final selection = int.tryParse(input ?? '');

    if (selection == null || selection < 1 || selection > options.length) {
      warn('Invalid selection, defaulting to 1');
      return 0;
    }

    return selection - 1;
  }
}
