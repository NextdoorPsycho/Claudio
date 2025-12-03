import 'dart:io';
import 'package:fast_log/fast_log.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;

import '../models/gen_config.dart';
import '../models/file_info.dart';
import '../models/language_config.dart';
import '../utils/ignore_patterns.dart';
import '../utils/comment_remover.dart';

/// Service for processing source files of any language
class FileProcessor {
  final GenConfig config;
  final String workingDir;

  FileProcessor(this.config, {String? workingDir})
      : workingDir = workingDir ?? Directory.current.path;

  /// Get the comment style for the current project
  CommentStyle get commentStyle => config.languageConfig.commentStyle;

  /// Discover all matching files in the source directory
  Stream<File> discoverFiles() async* {
    final sourceDir = p.join(workingDir, config.sourceDir);
    final dir = Directory(sourceDir);

    if (!dir.existsSync()) {
      throw FileSystemException(
        'Source directory does not exist: ${config.sourceDir}',
        sourceDir,
      );
    }

    final extensions = config.effectiveExtensions;

    // Create glob patterns for each extension
    for (final ext in extensions) {
      // Remove leading dot if present for glob pattern
      final extPattern = ext.startsWith('.') ? ext.substring(1) : ext;
      final glob = Glob('**.$extPattern');

      await for (final FileSystemEntity entity in glob.list(root: sourceDir)) {
        final file = File(entity.path);
        if (await file.exists()) {
          yield file;
        }
      }
    }
  }

  /// Process a single file and return FileInfo
  Future<FileInfo> processFile(File file) async {
    final relativePath = p.relative(file.path, from: p.join(workingDir, config.sourceDir));

    // Check if file should be ignored (pattern check first, no I/O)
    final patternReason = IgnorePatterns.getIgnoreReason(
      relativePath,
      null,
      config.effectiveIgnorePatterns,
      config.ignoreFiles,
    );

    if (patternReason != null) {
      return FileInfo.ignored(
        path: file.path,
        relativePath: relativePath,
        reason: patternReason,
      );
    }

    // Read file content
    String content;
    try {
      content = await file.readAsString();
    } catch (e) {
      return FileInfo.ignored(
        path: file.path,
        relativePath: relativePath,
        reason: 'Could not read file: $e',
      );
    }

    // Check for generated markers in content (language-aware)
    if (IgnorePatterns.hasGeneratedMarker(content, commentStyle)) {
      return FileInfo.ignored(
        path: file.path,
        relativePath: relativePath,
        reason: 'Contains generated file marker',
      );
    }

    // Get file stats
    final stat = await file.stat();

    // Process content (remove comments if configured)
    final processedContent = config.removeComments
        ? CommentRemover.removeComments(content, commentStyle)
        : content;

    return FileInfo(
      path: file.path,
      relativePath: relativePath,
      sizeBytes: stat.size,
      lastModified: stat.modified,
      content: processedContent,
    );
  }

  /// Process all files and collect results
  Future<ProcessingResult> processAllFiles({
    void Function(FileInfo info)? onFileProcessed,
    void Function(int processed, int total)? onProgress,
  }) async {
    final files = <FileInfo>[];
    final ignoredFiles = <FileInfo>[];
    final ignoreReasons = <String, int>{};

    // First, collect all files to get total count
    final allFiles = await discoverFiles().toList();
    final int total = allFiles.length;
    int processed = 0;

    for (final file in allFiles) {
      final info = await processFile(file);
      processed++;

      if (info.wasIgnored) {
        ignoredFiles.add(info);
        final String reason = info.ignoreReason ?? 'Unknown';
        ignoreReasons[reason] = (ignoreReasons[reason] ?? 0) + 1;

        if (config.verbose) {
          verbose('Ignoring: ${info.relativePath} ($reason)');
        }
      } else {
        files.add(info);

        if (config.verbose) {
          verbose('Processing: ${info.relativePath}');
        }
      }

      onFileProcessed?.call(info);
      onProgress?.call(processed, total);
    }

    return ProcessingResult(
      files: files,
      ignoredFiles: ignoredFiles,
      ignoreReasons: ignoreReasons,
    );
  }

  /// Clean previous output files
  Future<int> cleanPreviousOutputs() async {
    final RegExp pattern = RegExp('${RegExp.escape(config.outputPrefix)}-\\d{3}\\.(txt|md|json)\$');
    int count = 0;

    await for (final FileSystemEntity entity in Directory(workingDir).list()) {
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

  /// Copy extra root files to output directory
  Future<List<String>> includeExtraRootFiles(String outputDir) async {
    final included = <String>[];

    for (final fileName in config.extraRootFiles) {
      final sourcePath = p.join(workingDir, fileName);
      final sourceFile = File(sourcePath);

      if (sourceFile.existsSync()) {
        final destPath = p.join(outputDir, fileName);
        final destFile = File(destPath);

        // Only copy if not already at destination
        if (destPath != sourcePath) {
          await destFile.parent.create(recursive: true);
          await sourceFile.copy(destPath);
        }

        included.add(fileName);

        if (config.verbose) {
          verbose('Included root file: $fileName');
        }
      } else if (config.verbose) {
        warn('Root file not found: $fileName');
      }
    }

    return included;
  }
}

/// Result of file processing
class ProcessingResult {
  final List<FileInfo> files;
  final List<FileInfo> ignoredFiles;
  final Map<String, int> ignoreReasons;

  const ProcessingResult({
    required this.files,
    required this.ignoredFiles,
    required this.ignoreReasons,
  });

  int get totalProcessed => files.length;
  int get totalIgnored => ignoredFiles.length;
  int get totalBytes => files.fold<int>(0, (int sum, FileInfo f) => sum + f.contentSize);
}
