import 'dart:io';
import 'package:fast_log/fast_log.dart';
import 'package:path/path.dart' as p;

import '../models/gen_config.dart';
import '../models/gen_stats.dart';
import '../models/source_folder.dart';
import 'file_processor.dart';
import 'output_generator.dart';

/// Result of processing a single source folder
class FolderProcessingResult {
  final SourceFolder folder;
  final ProcessingResult processingResult;
  final List<String> outputPaths;
  final int totalBytes;

  const FolderProcessingResult({
    required this.folder,
    required this.processingResult,
    required this.outputPaths,
    required this.totalBytes,
  });

  String get outputPrefix => folder.suffix != null && folder.suffix!.isNotEmpty
      ? folder.suffix!
      : 'main';
}

/// Result of processing multiple source folders
class MultiSourceResult {
  final List<FolderProcessingResult> folderResults;
  final Duration duration;

  const MultiSourceResult({
    required this.folderResults,
    required this.duration,
  });

  int get totalFilesProcessed =>
      folderResults.fold<int>(0, (int sum, FolderProcessingResult r) => sum + r.processingResult.totalProcessed);

  int get totalFilesIgnored =>
      folderResults.fold<int>(0, (int sum, FolderProcessingResult r) => sum + r.processingResult.totalIgnored);

  int get totalOutputFiles =>
      folderResults.fold<int>(0, (int sum, FolderProcessingResult r) => sum + r.outputPaths.length);

  int get totalBytes =>
      folderResults.fold<int>(0, (int sum, FolderProcessingResult r) => sum + r.totalBytes);

  List<String> get allOutputPaths =>
      folderResults.expand((FolderProcessingResult r) => r.outputPaths).toList();

  /// Get combined ignore reasons across all folders
  Map<String, int> get allIgnoreReasons {
    final Map<String, int> combined = {};
    for (final FolderProcessingResult result in folderResults) {
      result.processingResult.ignoreReasons.forEach((String key, int value) {
        combined[key] = (combined[key] ?? 0) + value;
      });
    }
    return combined;
  }

  /// Print a summary of all folder results
  void printSummary() {
    print('');
    print('━━━ Multi-Folder Summary ━━━');
    print('');

    for (final FolderProcessingResult result in folderResults) {
      final String prefix = result.outputPrefix;
      final int files = result.processingResult.totalProcessed;
      final int outputs = result.outputPaths.length;
      print('  📁 ${result.folder.path} → $prefix');
      print('     $files files → $outputs output(s)');
    }

    print('');
    print('━━━ Totals ━━━');
    print('  Files processed: $totalFilesProcessed');
    print('  Files ignored:   $totalFilesIgnored');
    print('  Output files:    $totalOutputFiles');
    print('  Total size:      ${_formatBytes(totalBytes)}');
    print('  Duration:        ${duration.inMilliseconds}ms');
    print('');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}

/// Service for processing multiple source folders
class MultiSourceProcessor {
  final GenConfig config;
  final String workingDir;
  final String outputDir;

  MultiSourceProcessor({
    required this.config,
    String? workingDir,
    String? outputDir,
  })  : workingDir = workingDir ?? Directory.current.path,
        outputDir = outputDir ?? Directory.current.path;

  /// Process all configured source folders
  Future<MultiSourceResult> processAllFolders({
    void Function(String folder, int processed, int total)? onProgress,
    void Function(String folder, String path)? onFileCreated,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final List<FolderProcessingResult> results = [];

    final List<SourceFolder> folders = config.enabledSourceFolders;

    if (folders.isEmpty) {
      // Fall back to single source directory mode
      final SourceFolder defaultFolder = SourceFolder(path: config.sourceDir);
      final FolderProcessingResult result = await _processSingleFolder(
        defaultFolder,
        config.outputPrefix,
        onProgress: onProgress,
        onFileCreated: onFileCreated,
      );
      results.add(result);
    } else {
      // Process each enabled folder
      for (final SourceFolder folder in folders) {
        final String prefix = folder.getOutputPrefix(config.outputPrefix);

        info('Processing folder: ${folder.path} → $prefix');

        final FolderProcessingResult result = await _processSingleFolder(
          folder,
          prefix,
          onProgress: onProgress,
          onFileCreated: onFileCreated,
        );
        results.add(result);
      }
    }

    stopwatch.stop();

    return MultiSourceResult(
      folderResults: results,
      duration: stopwatch.elapsed,
    );
  }

  /// Process a single folder
  Future<FolderProcessingResult> _processSingleFolder(
    SourceFolder folder,
    String outputPrefix,
    {
    void Function(String folder, int processed, int total)? onProgress,
    void Function(String folder, String path)? onFileCreated,
  }) async {
    // Create a config for this specific folder
    final GenConfig folderConfig = config.copyWith(
      sourceDir: folder.path,
      outputPrefix: outputPrefix,
    );

    final FileProcessor processor = FileProcessor(folderConfig, workingDir: workingDir);
    final OutputGenerator generator = OutputGenerator(folderConfig, outputDir);

    // Clean previous outputs for this prefix
    await _cleanOutputsForPrefix(outputPrefix);

    // Process files
    final ProcessingResult result = await processor.processAllFiles(
      onProgress: onProgress != null
          ? (int processed, int total) => onProgress(folder.path, processed, total)
          : null,
    );

    // Generate outputs
    final List<String> outputPaths = await generator.generateOutputs(
      result.files,
      onFileCreated: onFileCreated != null
          ? (String path) => onFileCreated(folder.path, path)
          : null,
    );

    // Get total size
    final int totalSize = await OutputGenerator.getTotalOutputSize(outputPaths);

    return FolderProcessingResult(
      folder: folder,
      processingResult: result,
      outputPaths: outputPaths,
      totalBytes: totalSize,
    );
  }

  /// Clean outputs for a specific prefix
  Future<int> _cleanOutputsForPrefix(String prefix) async {
    final RegExp pattern = RegExp('${RegExp.escape(prefix)}-\\d{3}\\.(txt|md|json)\$');
    int count = 0;

    await for (final FileSystemEntity entity in Directory(outputDir).list()) {
      if (entity is File && pattern.hasMatch(p.basename(entity.path))) {
        await entity.delete();
        count++;
        if (config.verbose) {
          verbose('Deleted: ${p.basename(entity.path)}');
        }
      }
    }

    return count;
  }

  /// Convert multi-source result to legacy GenStats for compatibility
  GenStats toGenStats(MultiSourceResult result) {
    return GenStats(
      filesProcessed: result.totalFilesProcessed,
      filesIgnored: result.totalFilesIgnored,
      outputFilesCreated: result.totalOutputFiles,
      outputFiles: result.allOutputPaths.map((String p) => p.split('/').last).toList(),
      totalBytes: result.totalBytes,
      duration: result.duration,
      ignoreReasons: result.allIgnoreReasons,
    );
  }
}
