import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'language_config.dart';

/// Output format for generated files
enum OutputFormat {
  text,
  markdown,
  json,
}

/// Configuration for the gen command
class GenConfig {
  /// Source directory to scan
  final String sourceDir;

  /// Output file prefix
  final String outputPrefix;

  /// Maximum size per output file in KB
  final int targetSizeKB;

  /// Whether to remove comments from output
  final bool removeComments;

  /// Project type (for language-specific handling)
  final String projectTypeName;

  /// Custom file extensions to include (overrides language defaults)
  final List<String> extensions;

  /// Patterns to ignore
  final List<String> ignorePatterns;

  /// Specific files to ignore
  final List<String> ignoreFiles;

  /// Extra root files to include in output
  final List<String> extraRootFiles;

  /// Output format name
  final String outputFormatName;

  /// Enable verbose output
  final bool verbose;

  const GenConfig({
    required this.sourceDir,
    this.outputPrefix = 'CLAUDIO',
    this.targetSizeKB = 1000,
    this.removeComments = true,
    this.projectTypeName = 'auto',
    this.extensions = const [],
    this.ignorePatterns = const [],
    this.ignoreFiles = const [],
    this.extraRootFiles = const [],
    this.outputFormatName = 'text',
    this.verbose = false,
  });

  /// Get the ProjectType enum value
  ProjectType get projectType => ProjectType.values.firstWhere(
        (t) => t.name == projectTypeName,
        orElse: () => ProjectType.auto,
      );

  /// Get the OutputFormat enum value
  OutputFormat get outputFormat => OutputFormat.values.firstWhere(
        (f) => f.name == outputFormatName,
        orElse: () => OutputFormat.text,
      );

  /// Get the language config for this project type
  LanguageConfig get languageConfig {
    final type = projectType == ProjectType.auto
        ? LanguageConfig.detectProjectType(sourceDir)
        : projectType;
    return LanguageConfig.forType(type);
  }

  /// Get effective file extensions (custom or from language config)
  List<String> get effectiveExtensions {
    if (extensions.isNotEmpty) return extensions;
    return languageConfig.extensions;
  }

  /// Get effective ignore patterns (merged with language defaults)
  List<String> get effectiveIgnorePatterns {
    final langPatterns = languageConfig.defaultIgnorePatterns;
    if (ignorePatterns.isEmpty) return langPatterns;
    // Merge custom patterns with language defaults
    return {...langPatterns, ...ignorePatterns}.toList();
  }

  /// Create config with sensible defaults
  factory GenConfig.withDefaults([String? workingDir]) {
    final dir = workingDir ?? Directory.current.path;
    final detectedType = LanguageConfig.detectProjectType(dir);
    final langConfig = LanguageConfig.forType(detectedType);

    // Find the first existing source directory
    String sourceDir = '.';
    for (final candidate in langConfig.defaultSourceDirs) {
      if (Directory(p.join(dir, candidate)).existsSync()) {
        sourceDir = candidate;
        break;
      }
    }

    return GenConfig(
      sourceDir: sourceDir,
      outputPrefix: 'CLAUDIO',
      targetSizeKB: 1000,
      removeComments: true,
      projectTypeName: detectedType.name,
      extensions: const [],
      ignorePatterns: const [],
      ignoreFiles: const [],
      extraRootFiles: _defaultExtraRootFiles(detectedType),
      outputFormatName: 'text',
      verbose: false,
    );
  }

  /// Get default extra root files based on project type
  static List<String> _defaultExtraRootFiles(ProjectType type) {
    switch (type) {
      case ProjectType.dart:
        return ['pubspec.yaml', 'analysis_options.yaml'];
      case ProjectType.python:
        return ['requirements.txt', 'pyproject.toml', 'setup.py'];
      case ProjectType.javascript:
      case ProjectType.typescript:
      case ProjectType.web:
        return ['package.json', 'tsconfig.json'];
      case ProjectType.go:
        return ['go.mod', 'go.sum'];
      case ProjectType.rust:
        return ['Cargo.toml'];
      case ProjectType.java:
      case ProjectType.kotlin:
        return ['pom.xml', 'build.gradle', 'build.gradle.kts'];
      case ProjectType.ruby:
        return ['Gemfile', 'Gemfile.lock'];
      case ProjectType.php:
        return ['composer.json'];
      default:
        return ['README.md'];
    }
  }

  /// Create config from YAML map
  factory GenConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return GenConfig(
      sourceDir: yaml['source_dir'] as String? ?? '.',
      outputPrefix: yaml['output_prefix'] as String? ?? 'CLAUDIO',
      targetSizeKB: yaml['target_size_kb'] as int? ?? 1000,
      removeComments: yaml['remove_comments'] as bool? ?? true,
      projectTypeName: yaml['project_type'] as String? ?? 'auto',
      extensions: (yaml['extensions'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const [],
      ignorePatterns: (yaml['ignore_patterns'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const [],
      ignoreFiles: (yaml['ignore_files'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const [],
      extraRootFiles: (yaml['extra_root_files'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const [],
      outputFormatName: yaml['output_format'] as String? ?? 'text',
      verbose: yaml['verbose'] as bool? ?? false,
    );
  }

  /// Load config from YAML file
  static Future<GenConfig?> loadFromFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;

    final content = await file.readAsString();
    final yaml = loadYaml(content);
    if (yaml is! Map) return null;

    return GenConfig.fromYaml(yaml);
  }

  /// Convert to YAML string
  String toYaml() {
    final buffer = StringBuffer();
    buffer.writeln('# Claudio Gen Configuration');
    buffer.writeln('# Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    buffer.writeln('# Project type: auto, dart, python, javascript, typescript, go, rust, java, kotlin, swift, cpp, csharp, ruby, php, web, generic');
    buffer.writeln('project_type: $projectTypeName');
    buffer.writeln();
    buffer.writeln('source_dir: $sourceDir');
    buffer.writeln('output_prefix: $outputPrefix');
    buffer.writeln('target_size_kb: $targetSizeKB');
    buffer.writeln('remove_comments: $removeComments');
    buffer.writeln('output_format: $outputFormatName');
    buffer.writeln('verbose: $verbose');

    if (extensions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('# Custom file extensions (overrides language defaults)');
      buffer.writeln('extensions:');
      for (final ext in extensions) {
        buffer.writeln('  - "$ext"');
      }
    }

    if (ignorePatterns.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('# Additional ignore patterns (merged with language defaults)');
      buffer.writeln('ignore_patterns:');
      for (final pattern in ignorePatterns) {
        buffer.writeln('  - "$pattern"');
      }
    }

    if (ignoreFiles.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('ignore_files:');
      for (final file in ignoreFiles) {
        buffer.writeln('  - "$file"');
      }
    }

    if (extraRootFiles.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('extra_root_files:');
      for (final file in extraRootFiles) {
        buffer.writeln('  - "$file"');
      }
    }

    return buffer.toString();
  }

  /// Save config to YAML file
  Future<void> saveToFile(String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(toYaml());
  }

  /// Create a copy with modified values
  GenConfig copyWith({
    String? sourceDir,
    String? outputPrefix,
    int? targetSizeKB,
    bool? removeComments,
    String? projectTypeName,
    List<String>? extensions,
    List<String>? ignorePatterns,
    List<String>? ignoreFiles,
    List<String>? extraRootFiles,
    String? outputFormatName,
    bool? verbose,
  }) {
    return GenConfig(
      sourceDir: sourceDir ?? this.sourceDir,
      outputPrefix: outputPrefix ?? this.outputPrefix,
      targetSizeKB: targetSizeKB ?? this.targetSizeKB,
      removeComments: removeComments ?? this.removeComments,
      projectTypeName: projectTypeName ?? this.projectTypeName,
      extensions: extensions ?? this.extensions,
      ignorePatterns: ignorePatterns ?? this.ignorePatterns,
      ignoreFiles: ignoreFiles ?? this.ignoreFiles,
      extraRootFiles: extraRootFiles ?? this.extraRootFiles,
      outputFormatName: outputFormatName ?? this.outputFormatName,
      verbose: verbose ?? this.verbose,
    );
  }

  /// Get the profiles directory path
  static String get profilesDir {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) {
      throw Exception('Could not determine home directory');
    }
    return p.join(home, '.claudio', 'profiles');
  }

  @override
  String toString() {
    return 'GenConfig(source: $sourceDir, type: $projectTypeName, prefix: $outputPrefix, '
        'size: ${targetSizeKB}KB, format: $outputFormatName)';
  }
}
