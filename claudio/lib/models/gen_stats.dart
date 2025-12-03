import 'package:fast_log/fast_log.dart';

/// Statistics from a generation run
class GenStats {
  /// Number of files successfully processed
  final int filesProcessed;

  /// Number of files ignored
  final int filesIgnored;

  /// Number of output files created
  final int outputFilesCreated;

  /// List of output file paths
  final List<String> outputFiles;

  /// Total bytes written
  final int totalBytes;

  /// Duration of the operation
  final Duration duration;

  /// Breakdown of ignore reasons
  final Map<String, int> ignoreReasons;

  const GenStats({
    required this.filesProcessed,
    required this.filesIgnored,
    required this.outputFilesCreated,
    required this.outputFiles,
    required this.totalBytes,
    required this.duration,
    required this.ignoreReasons,
  });

  /// Create empty stats
  factory GenStats.empty() {
    return const GenStats(
      filesProcessed: 0,
      filesIgnored: 0,
      outputFilesCreated: 0,
      outputFiles: [],
      totalBytes: 0,
      duration: Duration.zero,
      ignoreReasons: {},
    );
  }

  /// Format bytes as human readable string
  String get formattedSize {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Format duration as human readable string
  String get formattedDuration {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    }
    return '${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s';
  }

  /// Print a beautiful summary to the console
  void printSummary() {
    print('');
    print('\u256d${'─' * 45}\u256e');
    print('\u2502 ${'Generation Summary'.padRight(43)} \u2502');
    print('\u251c${'─' * 45}\u2524');
    print('\u2502 Files Processed:    ${filesProcessed.toString().padLeft(20)} \u2502');
    print('\u2502 Files Ignored:      ${filesIgnored.toString().padLeft(20)} \u2502');
    print('\u2502 Output Files:       ${outputFilesCreated.toString().padLeft(20)} \u2502');

    // Show individual output files
    for (final file in outputFiles) {
      final name = file.length > 38 ? '...${file.substring(file.length - 35)}' : file;
      print('\u2502   \u2022 ${name.padRight(40)} \u2502');
    }

    print('\u2502 Total Size:         ${formattedSize.padLeft(20)} \u2502');
    print('\u2502 Duration:           ${formattedDuration.padLeft(20)} \u2502');
    print('\u2570${'─' * 45}\u256f');

    // Show ignore breakdown if there are ignored files
    if (ignoreReasons.isNotEmpty) {
      print('');
      info('Ignore breakdown:');
      for (final entry in ignoreReasons.entries) {
        print('  \u2022 ${entry.key}: ${entry.value} file(s)');
      }
    }
  }

  @override
  String toString() {
    return 'GenStats(processed: $filesProcessed, ignored: $filesIgnored, '
        'outputs: $outputFilesCreated, size: $formattedSize, '
        'duration: $formattedDuration)';
  }
}
