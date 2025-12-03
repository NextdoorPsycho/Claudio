import 'dart:async';
import 'dart:io';
import 'package:fast_log/fast_log.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../models/gen_config.dart';
import '../models/gen_stats.dart';
import 'file_processor.dart';
import 'output_generator.dart';

/// Service for watching file changes and triggering regeneration
class FileWatcher {
  final GenConfig config;
  final String workingDir;
  final Duration debounceDelay;

  DirectoryWatcher? _watcher;
  StreamSubscription<WatchEvent>? _subscription;
  Timer? _debounceTimer;
  bool _isProcessing = false;

  FileWatcher(
    this.config, {
    String? workingDir,
    this.debounceDelay = const Duration(milliseconds: 500),
  }) : workingDir = workingDir ?? Directory.current.path;

  /// Start watching for file changes
  Future<void> startWatching({
    void Function(GenStats stats)? onBuildComplete,
    void Function(String error)? onError,
  }) async {
    final sourceDir = p.join(workingDir, config.sourceDir);

    if (!Directory(sourceDir).existsSync()) {
      throw FileSystemException(
        'Source directory does not exist: ${config.sourceDir}',
        sourceDir,
      );
    }

    // Create watcher
    _watcher = DirectoryWatcher(sourceDir);

    info('Watch mode started');
    info('Watching: $sourceDir');
    info('Press Ctrl+C to stop');
    print('');

    // Do initial build
    await _doBuild(onBuildComplete, onError, isInitial: true);

    // Start listening for changes
    _subscription = _watcher!.events.listen(
      (WatchEvent event) => _onFileChange(event, onBuildComplete, onError),
      onError: (Object e) {
        error('Watch error: $e');
        onError?.call(e.toString());
      },
    );

    // Keep running until cancelled
    await _watcher!.ready;
  }

  /// Stop watching
  Future<void> stopWatching() async {
    _debounceTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    _watcher = null;
    info('Watch mode stopped');
  }

  /// Handle a file change event
  void _onFileChange(
    WatchEvent event,
    void Function(GenStats stats)? onBuildComplete,
    void Function(String error)? onError,
  ) {
    // Only react to .dart files
    if (!event.path.endsWith('.dart')) {
      return;
    }

    // Get relative path for display
    final relativePath = p.relative(event.path, from: p.join(workingDir, config.sourceDir));

    // Log the change
    final changeType = switch (event.type) {
      ChangeType.ADD => 'Added',
      ChangeType.MODIFY => 'Modified',
      ChangeType.REMOVE => 'Removed',
      _ => 'Changed',
    };

    verbose('$changeType: $relativePath');

    // Debounce multiple rapid changes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDelay, () {
      _doBuild(onBuildComplete, onError, isInitial: false);
    });
  }

  /// Perform a build
  Future<void> _doBuild(
    void Function(GenStats stats)? onBuildComplete,
    void Function(String error)? onError, {
    required bool isInitial,
  }) async {
    // Skip if already processing
    if (_isProcessing) {
      verbose('Build already in progress, skipping...');
      return;
    }

    _isProcessing = true;
    final stopwatch = Stopwatch()..start();

    try {
      if (isInitial) {
        info('Initial build starting...');
      } else {
        print('');
        info('Change detected, rebuilding...');
      }

      // Create processor and generator
      final processor = FileProcessor(config, workingDir: workingDir);
      final generator = OutputGenerator(config, workingDir);

      // Clean previous outputs
      final cleaned = await processor.cleanPreviousOutputs();
      if (cleaned > 0 && config.verbose) {
        verbose('Cleaned $cleaned previous output file(s)');
      }

      // Process files
      final result = await processor.processAllFiles(
        onProgress: config.verbose
            ? (processed, total) => verbose('Processing: $processed/$total')
            : null,
      );

      // Generate outputs
      final outputPaths = await generator.generateOutputs(result.files);

      // Get total output size
      final totalSize = await OutputGenerator.getTotalOutputSize(outputPaths);

      stopwatch.stop();

      // Create stats
      final stats = GenStats(
        filesProcessed: result.totalProcessed,
        filesIgnored: result.totalIgnored,
        outputFilesCreated: outputPaths.length,
        outputFiles: outputPaths.map((String p) => p.split('/').last).toList(),
        totalBytes: totalSize,
        duration: stopwatch.elapsed,
        ignoreReasons: result.ignoreReasons,
      );

      success('Build complete (${stats.formattedDuration})');

      if (config.verbose) {
        stats.printSummary();
      } else {
        info('${stats.filesProcessed} files -> ${stats.outputFilesCreated} output(s) (${stats.formattedSize})');
      }

      onBuildComplete?.call(stats);
    } catch (e, stack) {
      stopwatch.stop();
      error('Build failed: $e');
      if (config.verbose) {
        error(stack.toString());
      }
      onError?.call(e.toString());
    } finally {
      _isProcessing = false;
    }
  }
}
