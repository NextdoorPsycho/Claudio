import 'dart:io';
import 'package:fast_log/fast_log.dart';
import 'package:path/path.dart' as p;

import '../models/gen_config.dart';
import '../models/language_config.dart';
import '../models/source_folder.dart';
import '../services/file_processor.dart';
import '../services/file_watcher.dart';
import '../services/multi_source_processor.dart';
import '../services/output_generator.dart';
import '../services/profile_manager.dart';
import '../models/gen_stats.dart';
import '../utils/user_prompt.dart';

/// Interactive wizard for guiding users through claudio setup
class InteractiveWizard {
  static const String _version = '1.0.0';

  /// Run the interactive wizard
  static Future<void> run() async {
    _printBanner();

    // Step 1: Choose action
    final action = await _chooseAction();

    switch (action) {
      case WizardAction.generate:
        await _runGenerateWizard();
        break;
      case WizardAction.multiFolder:
        await _runMultiFolderWizard();
        break;
      case WizardAction.allFiles:
        await _runAllFilesWizard();
        break;
      case WizardAction.watch:
        await _runWatchWizard();
        break;
      case WizardAction.init:
        await _runInitWizard();
        break;
      case WizardAction.profiles:
        await _runProfilesWizard();
        break;
      case WizardAction.help:
        _printHelp();
        break;
      case WizardAction.exit:
        print('\nGoodbye!\n');
        break;
    }
  }

  /// Print the welcome banner
  static void _printBanner() {
    const String cyan = '\x1B[36m';
    const String yellow = '\x1B[33m';
    const String reset = '\x1B[0m';
    const String bold = '\x1B[1m';

    print('');
    print('$cyan$bold  ╔═════════════════════════════════════════════════╗$reset');
    print('$cyan$bold  ║$reset$yellow       _____ _                 _ _             $cyan$bold  ║$reset');
    print('$cyan$bold  ║$reset$yellow      / ____| |               | (_)            $cyan$bold  ║$reset');
    print('$cyan$bold  ║$reset$yellow     | |    | | __ _ _   _  __| |_  ___        $cyan$bold  ║$reset');
    print('$cyan$bold  ║$reset$yellow     | |    | |/ _` | | | |/ _` | |/ _ \\       $cyan$bold  ║$reset');
    print('$cyan$bold  ║$reset$yellow     | |____| | (_| | |_| | (_| | | (_) |      $cyan$bold  ║$reset');
    print('$cyan$bold  ║$reset$yellow      \\_____|_|\\__,_|\\__,_|\\__,_|_|\\___/       $cyan$bold  ║$reset');
    print('$cyan$bold  ║$reset                                                 $cyan$bold║$reset');
    print('$cyan$bold  ║$reset  ${_dim('Universal source bundler for LLM consumption')}   $cyan$bold║$reset');
    print('$cyan$bold  ║$reset  ${_dim('Version $_version')}                                  $cyan$bold║$reset');
    print('$cyan$bold  ║$reset  ${_italic('no relation to claude ')}                          $cyan$bold║$reset');
    print('$cyan$bold  ╚═════════════════════════════════════════════════╝$reset');
    print('');
  }

  static String _dim(String text) => '\x1B[2m$text\x1B[0m';
  static String _italic(String text) => '\x1B[3m$text\x1B[0m';
  static String _bold(String text) => '\x1B[1m$text\x1B[0m';
  static String _green(String text) => '\x1B[32m$text\x1B[0m';
  static String _cyan(String text) => '\x1B[36m$text\x1B[0m';
  static String _yellow(String text) => '\x1B[33m$text\x1B[0m';

  /// Choose the main action
  static Future<WizardAction> _chooseAction() async {
    print('${_bold('What would you like to do?')}\n');

    const List<_MenuOption> options = [
      _MenuOption('Generate', 'Bundle source files for LLM consumption', '📦'),
      _MenuOption('Multi-Folder', 'Process multiple folders with separate outputs', '📂'),
      _MenuOption('All Files', 'Scan ALL supported file types in project', '🌐'),
      _MenuOption('Watch', 'Auto-regenerate when files change', '👁'),
      _MenuOption('Init', 'Create a .claudio.yaml config file', '⚙'),
      _MenuOption('Profiles', 'Manage saved configuration profiles', '💾'),
      _MenuOption('Help', 'Show help and documentation', '❓'),
      _MenuOption('Exit', 'Exit the wizard', '👋'),
    ];

    final int selection = await _showFancyMenu(options);

    return WizardAction.values[selection];
  }

  /// Show a fancy menu with icons
  static Future<int> _showFancyMenu(List<_MenuOption> options) async {
    for (int i = 0; i < options.length; i++) {
      final opt = options[i];
      final num = '${i + 1}'.padLeft(2);
      print('  $num. ${opt.icon}  ${_bold(opt.title)}');
      print('      ${_dim(opt.description)}');
    }

    print('');
    stdout.write('${_cyan('→')} Enter choice [1-${options.length}]: ');

    final String? input = stdin.readLineSync()?.trim();
    final int? selection = int.tryParse(input ?? '');

    if (selection == null || selection < 1 || selection > options.length) {
      print('${_yellow('Invalid selection, defaulting to Generate')}\n');
      return 0;
    }

    return selection - 1;
  }

  /// Run the generate wizard
  static Future<void> _runGenerateWizard() async {
    print('\n${_bold('━━━ Generate Source Bundle ━━━')}\n');

    // Detect project type
    final String workingDir = Directory.current.path;
    final ProjectType detectedType = LanguageConfig.detectProjectType(workingDir);
    final LanguageConfig langConfig = LanguageConfig.forType(detectedType);

    print('${_green('✓')} Detected project type: ${_bold(detectedType.name)}');
    print('  ${_dim('Extensions: ${langConfig.extensions.join(", ")}')}');
    print('');

    // Ask if they want to use detected settings or customize
    final bool customize = await _askYesNo(
      'Would you like to customize settings?',
      defaultValue: false,
    );

    GenConfig config;

    if (customize) {
      config = await _customizeConfig(detectedType, workingDir);
    } else {
      config = GenConfig.withDefaults(workingDir);
    }

    // Show preview
    print('\n${_bold('━━━ Configuration Summary ━━━')}');
    UserPrompt.printConfigPreview(config);

    // Confirm
    final bool proceed = await _askYesNo('\nProceed with generation?', defaultValue: true);

    if (!proceed) {
      print('\n${_yellow('Operation cancelled.')}\n');
      return;
    }

    // Run generation
    print('\n${_bold('━━━ Generating... ━━━')}\n');
    await _runGeneration(config, workingDir);
  }

  /// Customize configuration interactively
  static Future<GenConfig> _customizeConfig(ProjectType detectedType, String workingDir) async {
    print('\n${_bold('━━━ Configuration ━━━')}\n');

    // Project type
    final bool changeType = await _askYesNo(
      'Change project type from ${detectedType.name}?',
      defaultValue: false,
    );

    ProjectType projectType = detectedType;
    if (changeType) {
      projectType = await _selectProjectType();
    }

    final LanguageConfig langConfig = LanguageConfig.forType(projectType);

    // Source directory
    String defaultSourceDir = '.';
    for (final String candidate in langConfig.defaultSourceDirs) {
      if (Directory(p.join(workingDir, candidate)).existsSync()) {
        defaultSourceDir = candidate;
        break;
      }
    }

    final String sourceDir = await _askString(
      'Source directory',
      defaultValue: defaultSourceDir,
    );

    // Output prefix
    final String outputPrefix = await _askString(
      'Output file prefix',
      defaultValue: 'CLAUDIO',
    );

    // Max size
    final int maxSize = await _askInt(
      'Maximum output file size (KB)',
      defaultValue: 1000,
    );

    // Output format
    final OutputFormat format = await _selectOutputFormat();

    // Remove comments
    final bool removeComments = await _askYesNo(
      'Remove comments from output?',
      defaultValue: true,
    );

    return GenConfig(
      sourceDir: sourceDir,
      outputPrefix: outputPrefix,
      targetSizeKB: maxSize,
      removeComments: removeComments,
      projectTypeName: projectType.name,
      outputFormatName: format.name,
    );
  }

  /// Select project type from menu
  static Future<ProjectType> _selectProjectType() async {
    print('\n${_bold('Select project type:')}\n');

    final List<ProjectType> types = ProjectType.values.where((ProjectType t) => t != ProjectType.auto).toList();

    for (int i = 0; i < types.length; i++) {
      final ProjectType type = types[i];
      final LanguageConfig config = LanguageConfig.forType(type);
      print('  ${(i + 1).toString().padLeft(2)}. ${type.name.padRight(12)} ${_dim(config.extensions.join(", "))}');
    }

    print('');
    stdout.write('${_cyan('→')} Enter choice [1-${types.length}]: ');

    final String? input = stdin.readLineSync()?.trim();
    final int? selection = int.tryParse(input ?? '');

    if (selection == null || selection < 1 || selection > types.length) {
      print('${_yellow('Invalid selection, using dart')}\n');
      return ProjectType.dart;
    }

    return types[selection - 1];
  }

  /// Select output format
  static Future<OutputFormat> _selectOutputFormat() async {
    print('\n${_bold('Select output format:')}\n');

    const List<_MenuOption> options = [
      _MenuOption('text', 'Plain text with file markers (default)', '📄'),
      _MenuOption('markdown', 'Markdown with syntax highlighting', '📝'),
      _MenuOption('json', 'JSON with metadata', '{}'),
    ];

    for (int i = 0; i < options.length; i++) {
      final _MenuOption opt = options[i];
      print('  ${i + 1}. ${opt.icon}  ${_bold(opt.title)} - ${_dim(opt.description)}');
    }

    print('');
    stdout.write('${_cyan('→')} Enter choice [1-3, default=1]: ');

    final String? input = stdin.readLineSync()?.trim();

    if (input == null || input.isEmpty) {
      return OutputFormat.text;
    }

    final int? selection = int.tryParse(input);

    if (selection == null || selection < 1 || selection > 3) {
      return OutputFormat.text;
    }

    return OutputFormat.values[selection - 1];
  }

  /// Run the multi-folder wizard
  static Future<void> _runMultiFolderWizard() async {
    print('\n${_bold('━━━ Multi-Folder Mode ━━━')}\n');
    print('Generate separate output files for each source folder.');
    print('Each folder gets its own output prefix (e.g., CLAUDIO_dev).\n');

    final String workingDir = Directory.current.path;

    // Detect available folders
    print('${_cyan('Scanning for folders...')}\n');
    final List<DetectedFolder> detected = await FolderDetector.detectFolders(workingDir);

    if (detected.isEmpty) {
      print('${_yellow('No folders with source files found.')}\n');
      return;
    }

    // Show detected folders
    print('${_bold('Detected folders:')}\n');
    for (int i = 0; i < detected.length; i++) {
      final DetectedFolder folder = detected[i];
      final String typeIcon = folder.type == FolderType.source ? '📁' : (folder.type == FolderType.extra ? '📂' : '📄');
      final String suggested = folder.suggested ? ' ${_green('(recommended)')}' : '';
      print('  ${(i + 1).toString().padLeft(2)}. $typeIcon ${folder.path}$suggested');
    }

    print('');
    print('${_dim('Enter folder numbers separated by commas (e.g., 1,3,5)')}\n');
    stdout.write('${_cyan('→')} Select folders to include: ');

    final String? input = stdin.readLineSync()?.trim();
    if (input == null || input.isEmpty) {
      print('${_yellow('No folders selected.')}\n');
      return;
    }

    // Parse selections
    final List<SourceFolder> selectedFolders = [];
    final List<String> parts = input.split(',');

    for (final String part in parts) {
      final int? index = int.tryParse(part.trim());
      if (index != null && index >= 1 && index <= detected.length) {
        final DetectedFolder folder = detected[index - 1];
        final String? suggestedSuffix = FolderDetector.getSuggestedSuffix(folder.path);

        // Ask for suffix
        print('');
        final String suffix = await _askString(
          'Output suffix for "${folder.path}"',
          defaultValue: suggestedSuffix ?? folder.path,
        );

        selectedFolders.add(SourceFolder(
          path: folder.path,
          suffix: suffix.isEmpty ? null : suffix,
        ));
      }
    }

    if (selectedFolders.isEmpty) {
      print('${_yellow('No valid folders selected.')}\n');
      return;
    }

    // Show what will be generated
    print('\n${_bold('━━━ Output Preview ━━━')}\n');
    for (final SourceFolder folder in selectedFolders) {
      final String prefix = folder.getOutputPrefix('CLAUDIO');
      print('  📁 ${folder.path} → ${_cyan(prefix)}-001.txt, ${_cyan(prefix)}-002.txt, ...');
    }

    // Get other settings
    print('');
    final ProjectType detectedType = LanguageConfig.detectProjectType(workingDir);
    final OutputFormat format = await _selectOutputFormat();
    final bool removeComments = await _askYesNo('Remove comments from output?', defaultValue: true);

    final GenConfig config = GenConfig(
      sourceDir: selectedFolders.first.path,
      outputPrefix: 'CLAUDIO',
      projectTypeName: detectedType.name,
      outputFormatName: format.name,
      removeComments: removeComments,
      sourceFolders: selectedFolders,
    );

    // Confirm
    final bool proceed = await _askYesNo('\nProceed with generation?', defaultValue: true);
    if (!proceed) {
      print('\n${_yellow('Operation cancelled.')}\n');
      return;
    }

    // Run multi-folder generation
    print('\n${_bold('━━━ Generating... ━━━')}\n');
    await _runMultiFolderGeneration(config, workingDir);
  }

  /// Run the all files wizard
  static Future<void> _runAllFilesWizard() async {
    print('\n${_bold('━━━ All Files Mode ━━━')}\n');
    print('Scan and bundle ALL supported file types in your project.');
    print('This ignores project type detection and includes everything.\n');

    final String workingDir = Directory.current.path;

    // Show what extensions will be included
    print('${_bold('Supported extensions:')}\n');
    print('  ${_dim(GenConfig.allSupportedExtensions.join(", "))}\n');

    // Ask for source directory
    final String sourceDir = await _askString('Source directory', defaultValue: '.');

    // Get settings
    final OutputFormat format = await _selectOutputFormat();
    final bool removeComments = await _askYesNo('Remove comments from output?', defaultValue: true);

    final GenConfig config = GenConfig(
      sourceDir: sourceDir,
      outputPrefix: 'CLAUDIO_ALL',
      projectTypeName: 'generic',
      outputFormatName: format.name,
      removeComments: removeComments,
      allFilesMode: true,
    );

    // Show preview
    print('\n${_bold('━━━ Configuration Summary ━━━')}');
    print('  Source:     $sourceDir');
    print('  Mode:       ${_cyan('All Files')}');
    print('  Extensions: ${_dim('ALL (${GenConfig.allSupportedExtensions.length} types)')}');
    print('  Format:     ${format.name}');
    print('  Comments:   ${removeComments ? "Removed" : "Kept"}');

    // Confirm
    final bool proceed = await _askYesNo('\nProceed with generation?', defaultValue: true);
    if (!proceed) {
      print('\n${_yellow('Operation cancelled.')}\n');
      return;
    }

    // Run generation
    print('\n${_bold('━━━ Generating... ━━━')}\n');
    await _runGeneration(config, workingDir);
  }

  /// Run multi-folder generation
  static Future<void> _runMultiFolderGeneration(GenConfig config, String workingDir) async {
    final MultiSourceProcessor processor = MultiSourceProcessor(
      config: config,
      workingDir: workingDir,
      outputDir: workingDir,
    );

    final MultiSourceResult result = await processor.processAllFolders(
      onProgress: (String folder, int processed, int total) {
        stdout.write('\r${_dim('[$folder]')} ${UserPrompt.makeProgressBar(processed, total, 20)} $processed/$total');
      },
      onFileCreated: (String folder, String path) {
        if (config.verbose) {
          print('  Created: ${p.basename(path)}');
        }
      },
    );

    print('');
    success('Generation complete!');
    result.printSummary();
  }

  /// Run the watch wizard
  static Future<void> _runWatchWizard() async {
    print('\n${_bold('━━━ Watch Mode ━━━')}\n');
    print('Watch mode monitors your source files and automatically');
    print('regenerates output when changes are detected.\n');

    final String workingDir = Directory.current.path;
    final GenConfig config = GenConfig.withDefaults(workingDir);

    print('${_green('✓')} Project type: ${config.projectTypeName}');
    print('${_green('✓')} Watching: ${config.sourceDir}');
    print('');

    final bool proceed = await _askYesNo('Start watch mode?', defaultValue: true);

    if (!proceed) {
      print('\n${_yellow('Cancelled.')}\n');
      return;
    }

    print('\n${_cyan('Starting watch mode...')}\n');
    print('${_dim('Press Ctrl+C to stop')}\n');

    final FileWatcher watcher = FileWatcher(config, workingDir: workingDir);
    await watcher.startWatching();
  }

  /// Run the init wizard
  static Future<void> _runInitWizard() async {
    print('\n${_bold('━━━ Initialize Configuration ━━━')}\n');

    final String configPath = p.join(Directory.current.path, '.claudio.yaml');
    final File configFile = File(configPath);

    if (configFile.existsSync()) {
      print('${_yellow('⚠')} Configuration file already exists at:');
      print('  ${_dim(configPath)}\n');

      final bool overwrite = await _askYesNo('Overwrite existing configuration?', defaultValue: false);

      if (!overwrite) {
        print('\n${_yellow('Cancelled.')}\n');
        return;
      }
    }

    final String workingDir = Directory.current.path;
    final ProjectType detectedType = LanguageConfig.detectProjectType(workingDir);

    print('${_green('✓')} Detected project type: ${_bold(detectedType.name)}');

    final GenConfig config = GenConfig.withDefaults(workingDir);
    await config.saveToFile(configPath);

    print('${_green('✓')} Configuration saved to: ${_dim(configPath)}');
    print('\n${_dim('Edit this file to customize your settings.')}\n');
  }

  /// Run the profiles wizard
  static Future<void> _runProfilesWizard() async {
    print('\n${_bold('━━━ Profile Management ━━━')}\n');

    const List<_MenuOption> options = [
      _MenuOption('List', 'View all saved profiles', '📋'),
      _MenuOption('Create', 'Create a new profile', '➕'),
      _MenuOption('Delete', 'Delete an existing profile', '🗑'),
      _MenuOption('Back', 'Return to main menu', '←'),
    ];

    final int selection = await _showFancyMenu(options);

    switch (selection) {
      case 0:
        await _listProfiles();
        break;
      case 1:
        await _createProfile();
        break;
      case 2:
        await _deleteProfile();
        break;
      case 3:
        return;
    }
  }

  static Future<void> _listProfiles() async {
    final ProfileManager manager = ProfileManager.withDefaults();
    final List<ProfileInfo> profiles = await manager.listProfiles();

    if (profiles.isEmpty) {
      print('\n${_yellow('No saved profiles found.')}\n');
      print('${_dim('Create one with the "Create" option.')}\n');
      return;
    }

    print('\n${_bold('Saved Profiles:')}\n');

    for (final ProfileInfo profile in profiles) {
      print('  ${_green('●')} ${_bold(profile.name)}');
      print('    Type: ${profile.config.projectTypeName}, Source: ${profile.config.sourceDir}');
      print('    Format: ${profile.config.outputFormatName}, Size: ${profile.config.targetSizeKB}KB');
      print('');
    }

    print('${_dim('Use with: claudio gen run --profile <name>')}\n');
  }

  static Future<void> _createProfile() async {
    print('\n${_bold('Create New Profile')}\n');

    final String name = await _askString('Profile name', defaultValue: null);

    if (name.isEmpty) {
      print('${_yellow('Profile name cannot be empty.')}\n');
      return;
    }

    final String workingDir = Directory.current.path;
    final ProjectType detectedType = LanguageConfig.detectProjectType(workingDir);
    final GenConfig config = await _customizeConfig(detectedType, workingDir);

    final ProfileManager manager = ProfileManager.withDefaults();
    await manager.saveProfile(name, config);

    print('\n${_green('✓')} Profile "$name" saved successfully!');
    print('${_dim('Use with: claudio gen run --profile $name')}\n');
  }

  static Future<void> _deleteProfile() async {
    final ProfileManager manager = ProfileManager.withDefaults();
    final List<ProfileInfo> profiles = await manager.listProfiles();

    if (profiles.isEmpty) {
      print('\n${_yellow('No profiles to delete.')}\n');
      return;
    }

    print('\n${_bold('Select profile to delete:')}\n');

    for (int i = 0; i < profiles.length; i++) {
      print('  ${i + 1}. ${profiles[i].name}');
    }

    print('');
    stdout.write('${_cyan('→')} Enter choice [1-${profiles.length}]: ');

    final String? input = stdin.readLineSync()?.trim();
    final int? selection = int.tryParse(input ?? '');

    if (selection == null || selection < 1 || selection > profiles.length) {
      print('${_yellow('Invalid selection.')}\n');
      return;
    }

    final String profileName = profiles[selection - 1].name;
    final bool confirm = await _askYesNo('Delete profile "$profileName"?', defaultValue: false);

    if (!confirm) {
      print('\n${_yellow('Cancelled.')}\n');
      return;
    }

    await manager.deleteProfile(profileName);
    print('\n${_green('✓')} Profile "$profileName" deleted.\n');
  }

  /// Print help information
  static void _printHelp() {
    print('\n${_bold('━━━ Claudio Help ━━━')}\n');

    print(_bold('DESCRIPTION'));
    print('  Claudio bundles source files from any programming language into');
    print('  chunked output files optimized for LLM context windows.\n');

    print(_bold('USAGE'));
    print('  ${_cyan('claudio')}                    Launch interactive wizard');
    print('  ${_cyan('claudio gen run')}            Generate output files');
    print('  ${_cyan('claudio gen run --yes')}      Generate without confirmation');
    print('  ${_cyan('claudio gen watch')}          Watch mode (auto-regenerate)');
    print('  ${_cyan('claudio gen init')}           Create .claudio.yaml config');
    print('  ${_cyan('claudio gen types')}          List supported project types');
    print('  ${_cyan('claudio gen profile list')}   List saved profiles\n');

    print(_bold('OPTIONS'));
    print('  ${_cyan('--source, -s')}     Source directory');
    print('  ${_cyan('--type, -t')}       Project type (dart, python, etc.)');
    print('  ${_cyan('--prefix, -p')}     Output file prefix');
    print('  ${_cyan('--max-size')}       Max output file size in KB');
    print('  ${_cyan('--format, -f')}     Output format (text, markdown, json)');
    print('  ${_cyan('--profile')}        Load settings from saved profile');
    print('  ${_cyan('--yes, -y')}        Skip confirmation prompts');
    print('  ${_cyan('--verbose, -v')}    Show detailed output\n');

    print(_bold('EXAMPLES'));
    print('  ${_dim('# Generate for a Python project')}');
    print('  claudio gen run --type python --source src\n');

    print('  ${_dim('# Generate markdown output')}');
    print('  claudio gen run --format markdown --yes\n');

    print('  ${_dim('# Save and use a profile')}');
    print('  claudio gen profile save myproject --type dart');
    print('  claudio gen run --profile myproject\n');

    print(_bold('SUPPORTED LANGUAGES'));
    print('  Dart, Python, JavaScript, TypeScript, Go, Rust, Java, Kotlin,');
    print('  Swift, C/C++, C#, Ruby, PHP, and web projects.\n');

    print('${_dim('For more info: https://github.com/NextdoorPsycho/Claudio')}\n');
  }

  /// Run the actual generation
  static Future<void> _runGeneration(GenConfig config, String workingDir) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    final FileProcessor processor = FileProcessor(config, workingDir: workingDir);
    final OutputGenerator generator = OutputGenerator(config, workingDir);

    // Clean previous outputs
    info('Cleaning previous outputs...');
    await processor.cleanPreviousOutputs();

    // Process files
    info('Processing files...');
    final ProcessingResult result = await processor.processAllFiles(
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
    final List<String> outputPaths = await generator.generateOutputs(result.files);

    // Get total size
    final int totalSize = await OutputGenerator.getTotalOutputSize(outputPaths);

    stopwatch.stop();

    // Create stats
    final GenStats stats = GenStats(
      filesProcessed: result.totalProcessed,
      filesIgnored: result.totalIgnored,
      outputFilesCreated: outputPaths.length,
      outputFiles: outputPaths.map((String p) => p.split('/').last).toList(),
      totalBytes: totalSize,
      duration: stopwatch.elapsed,
      ignoreReasons: result.ignoreReasons,
    );

    print('');
    success('Generation complete!');
    stats.printSummary();
  }

  // Helper methods
  static Future<bool> _askYesNo(String question, {required bool defaultValue}) async {
    final String hint = defaultValue ? '[Y/n]' : '[y/N]';
    stdout.write('$question $hint: ');

    final String? input = stdin.readLineSync()?.trim().toLowerCase();

    if (input == null || input.isEmpty) {
      return defaultValue;
    }

    return input == 'y' || input == 'yes';
  }

  static Future<String> _askString(String question, {String? defaultValue}) async {
    if (defaultValue != null) {
      stdout.write('$question [$defaultValue]: ');
    } else {
      stdout.write('$question: ');
    }

    final String? input = stdin.readLineSync()?.trim();

    if (input == null || input.isEmpty) {
      return defaultValue ?? '';
    }

    return input;
  }

  static Future<int> _askInt(String question, {required int defaultValue}) async {
    stdout.write('$question [$defaultValue]: ');

    final String? input = stdin.readLineSync()?.trim();

    if (input == null || input.isEmpty) {
      return defaultValue;
    }

    return int.tryParse(input) ?? defaultValue;
  }
}

/// Wizard action options
enum WizardAction {
  generate,
  multiFolder,
  allFiles,
  watch,
  init,
  profiles,
  help,
  exit,
}

/// Menu option with icon and description
class _MenuOption {
  final String title;
  final String description;
  final String icon;

  const _MenuOption(this.title, this.description, this.icon);
}
