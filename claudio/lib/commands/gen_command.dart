import 'dart:io';
import 'package:cli_annotations/cli_annotations.dart';
import 'package:fast_log/fast_log.dart';
import 'package:path/path.dart' as p;

import '../models/gen_config.dart';
import '../models/gen_stats.dart';
import '../models/language_config.dart';
import '../services/file_processor.dart';
import '../services/output_generator.dart';
import '../services/file_watcher.dart';
import '../services/profile_manager.dart';
import '../utils/user_prompt.dart';

part 'gen_command.g.dart';

/// Generate combined source files for LLM consumption
///
/// Combines source files from a directory into chunked output files.
/// Supports multiple languages, output formats, watch mode, and profiles.
@cliSubcommand
class GenCommand extends _$GenCommand {
  /// Generate combined output files from source code
  ///
  /// Scans the source directory for files, applies ignore patterns,
  /// optionally removes comments, and generates chunked output files.
  @override
  @cliCommand
  Future<void> run({
    /// Source directory to scan (default: auto-detect)
    String? source,

    /// Project type: auto, dart, python, javascript, typescript, go, rust, java, kotlin, swift, cpp, csharp, ruby, php, web, generic
    String? type,

    /// Output file prefix (default: CLAUDIO)
    String? prefix,

    /// Maximum size per output file in KB (default: 1000)
    int? maxSize,

    /// Remove comments from output (default: true)
    bool? removeComments,

    /// Output format: text, markdown, or json (default: text)
    String? format,

    /// Load settings from a saved profile
    String? profile,

    /// Skip interactive confirmation
    bool yes = false,

    /// Show verbose output
    bool verbose = false,
  }) async {
    try {
      // Build configuration
      final config = await _buildConfig(
        source: source,
        type: type,
        prefix: prefix,
        maxSize: maxSize,
        removeComments: removeComments,
        format: format,
        profile: profile,
        verbose: verbose,
      );

      // Interactive confirmation (unless --yes)
      if (!yes) {
        final confirmed = await UserPrompt.confirmConfiguration(config);
        if (!confirmed) {
          warn('Operation cancelled by user');
          return;
        }
      }

      // Run the generation
      await _runGeneration(config);
    } catch (e) {
      error('Generation failed: $e');
      exit(1);
    }
  }

  /// Watch mode - auto-regenerate when source files change
  ///
  /// Monitors the source directory for changes and automatically
  /// regenerates output files when files are modified.
  @cliCommand
  Future<void> watch({
    /// Source directory to watch (default: auto-detect)
    String? source,

    /// Project type: auto, dart, python, javascript, typescript, go, rust, java, kotlin, swift, cpp, csharp, ruby, php, web, generic
    String? type,

    /// Output file prefix (default: CLAUDIO)
    String? prefix,

    /// Maximum size per output file in KB (default: 1000)
    int? maxSize,

    /// Remove comments from output (default: true)
    bool? removeComments,

    /// Output format: text, markdown, or json (default: text)
    String? format,

    /// Load settings from a saved profile
    String? profile,

    /// Show verbose output
    bool verbose = false,
  }) async {
    try {
      // Build configuration
      final config = await _buildConfig(
        source: source,
        type: type,
        prefix: prefix,
        maxSize: maxSize,
        removeComments: removeComments,
        format: format,
        profile: profile,
        verbose: verbose,
      );

      // Start watching
      final watcher = FileWatcher(config);
      await watcher.startWatching();
    } catch (e) {
      error('Watch mode failed: $e');
      exit(1);
    }
  }

  /// Initialize a project-local configuration file
  ///
  /// Creates a .claudio.yaml file in the current directory with
  /// default settings that can be customized.
  @cliCommand
  Future<void> init({
    /// Project type to use (default: auto-detect)
    String? type,

    /// Overwrite existing configuration
    bool force = false,
  }) async {
    final configPath = p.join(Directory.current.path, '.claudio.yaml');
    final configFile = File(configPath);

    if (configFile.existsSync() && !force) {
      warn('Configuration already exists at: $configPath');
      info('Use --force to overwrite');
      return;
    }

    // Auto-detect or use specified project type
    final projectType = type != null
        ? ProjectType.values.firstWhere(
            (t) => t.name == type,
            orElse: () => ProjectType.auto,
          )
        : LanguageConfig.detectProjectType(Directory.current.path);

    final config = GenConfig.withDefaults().copyWith(
      projectTypeName: projectType.name,
    );

    await config.saveToFile(configPath);

    success('Configuration initialized at: $configPath');
    info('Detected project type: ${projectType.name}');
    info('Edit this file to customize your settings');
  }

  /// List supported project types
  @cliCommand
  Future<void> types() async {
    print('\nSupported Project Types:');
    print('\u2500' * 60);

    for (final type in ProjectType.values) {
      if (type == ProjectType.auto) continue;

      final config = LanguageConfig.forType(type);
      final exts = config.extensions.join(', ');
      print('  ${type.name.padRight(12)} - $exts');
    }

    print('\u2500' * 60);
    info('Use --type <name> to specify a project type');
    info('Use "auto" to auto-detect based on project files');
  }

  /// Profile management commands
  @cliMount
  ProfileCommand get profile => ProfileCommand();

  /// Build configuration from various sources
  Future<GenConfig> _buildConfig({
    String? source,
    String? type,
    String? prefix,
    int? maxSize,
    bool? removeComments,
    String? format,
    String? profile,
    bool verbose = false,
  }) async {
    GenConfig baseConfig;

    // Priority: profile > project config > defaults
    if (profile != null) {
      final manager = ProfileManager.withDefaults();
      baseConfig = await manager.loadProfile(profile);
      info('Loaded profile: $profile');
    } else {
      final manager = ProfileManager.withDefaults();
      final projectConfig = await manager.loadProjectConfig();

      if (projectConfig != null) {
        baseConfig = projectConfig;
        info('Using project configuration from .claudio.yaml');
      } else {
        baseConfig = GenConfig.withDefaults();
      }
    }

    // Override with CLI flags
    return baseConfig.copyWith(
      sourceDir: source ?? baseConfig.sourceDir,
      projectTypeName: type ?? baseConfig.projectTypeName,
      outputPrefix: prefix ?? baseConfig.outputPrefix,
      targetSizeKB: maxSize ?? baseConfig.targetSizeKB,
      removeComments: removeComments ?? baseConfig.removeComments,
      outputFormatName: format ?? baseConfig.outputFormatName,
      verbose: verbose,
    );
  }

  /// Run the actual generation process
  Future<void> _runGeneration(GenConfig config) async {
    final stopwatch = Stopwatch()..start();
    final workingDir = Directory.current.path;

    // Show detected project type
    info('Project type: ${config.projectTypeName}');
    info('File extensions: ${config.effectiveExtensions.join(", ")}');

    // Create processor and generator
    final processor = FileProcessor(config, workingDir: workingDir);
    final generator = OutputGenerator(config, workingDir);

    // Clean previous outputs
    info('Cleaning previous outputs...');
    final cleaned = await processor.cleanPreviousOutputs();
    if (cleaned > 0) {
      verbose('Removed $cleaned previous output file(s)');
    }

    // Process files
    info('Processing files...');
    final result = await processor.processAllFiles(
      onProgress: (int processed, int total) {
        UserPrompt.showProgress(processed, total, '');
      },
    );

    if (result.files.isEmpty) {
      warn('No files to process after applying ignore rules');
      return;
    }

    // Generate outputs
    info('Generating outputs...');
    final outputPaths = await generator.generateOutputs(
      result.files,
      onFileCreated: (path) {
        if (config.verbose) {
          verbose('Created: ${p.basename(path)}');
        }
      },
    );

    // Get total output size
    final totalSize = await OutputGenerator.getTotalOutputSize(outputPaths);

    stopwatch.stop();

    // Create and display stats
    final stats = GenStats(
      filesProcessed: result.totalProcessed,
      filesIgnored: result.totalIgnored,
      outputFilesCreated: outputPaths.length,
      outputFiles: outputPaths.map((String p) => p.split('/').last).toList(),
      totalBytes: totalSize,
      duration: stopwatch.elapsed,
      ignoreReasons: result.ignoreReasons,
    );

    success('Generation complete!');
    stats.printSummary();
  }
}

/// Profile management subcommand
@cliSubcommand
class ProfileCommand extends _$ProfileCommand {
  /// Save current settings as a named profile
  ///
  /// Profiles are stored in ~/.claudio/profiles/ and can be
  /// loaded with the --profile flag.
  @cliCommand
  Future<void> save(
    /// Profile name (alphanumeric, hyphens, underscores)
    String name, {
    /// Source directory
    String? source,

    /// Project type
    String? type,

    /// Output prefix
    String? prefix,

    /// Max size in KB
    int? maxSize,

    /// Remove comments
    bool removeComments = true,

    /// Output format (text, markdown, json)
    String format = 'text',
  }) async {
    final config = GenConfig.withDefaults().copyWith(
      sourceDir: source,
      projectTypeName: type,
      outputPrefix: prefix,
      targetSizeKB: maxSize,
      removeComments: removeComments,
      outputFormatName: format,
    );

    final manager = ProfileManager.withDefaults();

    if (await manager.profileExists(name)) {
      final overwrite = await UserPrompt.askYesNo(
        'Profile "$name" already exists. Overwrite?',
        defaultValue: false,
      );
      if (!overwrite) {
        warn('Cancelled');
        return;
      }
    }

    await manager.saveProfile(name, config);
    success('Profile "$name" saved successfully');
    info('Use with: claudio gen run --profile $name');
  }

  /// Show details of a saved profile
  @cliCommand
  Future<void> show(
    /// Profile name
    String name,
  ) async {
    final manager = ProfileManager.withDefaults();

    try {
      final config = await manager.loadProfile(name);
      print('\nProfile: $name');
      UserPrompt.printConfigPreview(config);
      print('');
      info('Use with: claudio gen run --profile $name');
    } on FileSystemException {
      error('Profile not found: $name');
      info('List available profiles with: claudio gen profile list');
    }
  }

  /// List all saved profiles
  @cliCommand
  Future<void> list() async {
    final manager = ProfileManager.withDefaults();
    final profiles = await manager.listProfiles();

    if (profiles.isEmpty) {
      info('No saved profiles found');
      info('Create one with: claudio gen profile save <name>');
      return;
    }

    print('\nSaved Profiles:');
    print('\u2500' * 60);

    for (final profile in profiles) {
      final config = profile.config;
      print('  \u2022 ${profile.name}');
      print('    Type: ${config.projectTypeName}, Source: ${config.sourceDir}');
      print('    Format: ${config.outputFormatName}, Size: ${config.targetSizeKB}KB');
      print('');
    }

    print('\u2500' * 60);
    success('Found ${profiles.length} profile(s)');
  }

  /// Delete a saved profile
  @cliCommand
  Future<void> delete(
    /// Profile name to delete
    String name,
  ) async {
    final manager = ProfileManager.withDefaults();

    if (!await manager.profileExists(name)) {
      error('Profile not found: $name');
      return;
    }

    final confirm = await UserPrompt.askYesNo(
      'Delete profile "$name"?',
      defaultValue: false,
    );

    if (!confirm) {
      warn('Cancelled');
      return;
    }

    await manager.deleteProfile(name);
    success('Profile "$name" deleted');
  }
}
