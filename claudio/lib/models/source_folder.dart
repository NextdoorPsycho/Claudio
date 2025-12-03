import 'dart:io';
import 'package:path/path.dart' as p;

/// Represents a source folder to be processed
class SourceFolder {
  /// The directory path (relative to working directory)
  final String path;

  /// Custom suffix for output files (e.g., "dev" -> CLAUDIO_dev-001.txt)
  /// If null or empty, uses default naming
  final String? suffix;

  /// Whether this folder is enabled for processing
  final bool enabled;

  const SourceFolder({
    required this.path,
    this.suffix,
    this.enabled = true,
  });

  /// Get the output prefix for this folder
  String getOutputPrefix(String basePrefix) {
    if (suffix == null || suffix!.isEmpty) {
      return basePrefix;
    }
    return '${basePrefix}_$suffix';
  }

  /// Create from YAML map
  factory SourceFolder.fromYaml(Map<dynamic, dynamic> yaml) {
    return SourceFolder(
      path: yaml['path'] as String? ?? '.',
      suffix: yaml['suffix'] as String?,
      enabled: yaml['enabled'] as bool? ?? true,
    );
  }

  /// Convert to YAML-compatible map
  Map<String, dynamic> toYaml() {
    return {
      'path': path,
      if (suffix != null && suffix!.isNotEmpty) 'suffix': suffix,
      if (!enabled) 'enabled': enabled,
    };
  }

  @override
  String toString() => 'SourceFolder($path${suffix != null ? ' -> _$suffix' : ''})';
}

/// Utility for detecting folders in a project
class FolderDetector {
  /// Common source folder names to look for
  static const List<String> commonSourceFolders = [
    'lib',
    'src',
    'source',
    'app',
    'core',
    'packages',
  ];

  /// Common non-source folders to suggest (dev, test, etc.)
  static const List<String> commonExtraFolders = [
    'dev',
    'test',
    'tests',
    'spec',
    'scripts',
    'tools',
    'bin',
    'examples',
    'example',
    'docs',
    'config',
  ];

  /// Folders to always ignore
  static const List<String> ignoredFolders = [
    '.git',
    '.svn',
    '.hg',
    'node_modules',
    '.dart_tool',
    'build',
    'dist',
    '.idea',
    '.vscode',
    '__pycache__',
    '.pytest_cache',
    'venv',
    '.venv',
    'env',
    '.env',
    'vendor',
    'target',
    'out',
    '.gradle',
    'Pods',
  ];

  /// Detect all relevant folders in a directory
  static Future<List<DetectedFolder>> detectFolders(String workingDir) async {
    final List<DetectedFolder> folders = [];
    final Directory dir = Directory(workingDir);

    if (!await dir.exists()) {
      return folders;
    }

    await for (final FileSystemEntity entity in dir.list()) {
      if (entity is Directory) {
        final String name = p.basename(entity.path);

        // Skip hidden and ignored folders
        if (name.startsWith('.') || ignoredFolders.contains(name)) {
          continue;
        }

        final FolderType type = _classifyFolder(name);
        final bool hasFiles = await _hasRelevantFiles(entity);

        if (hasFiles) {
          folders.add(DetectedFolder(
            path: name,
            type: type,
            suggested: type == FolderType.source,
          ));
        }
      }
    }

    // Sort: source folders first, then extras, then others
    folders.sort((DetectedFolder a, DetectedFolder b) {
      if (a.type != b.type) {
        return a.type.index.compareTo(b.type.index);
      }
      return a.path.compareTo(b.path);
    });

    return folders;
  }

  /// Classify a folder by its name
  static FolderType _classifyFolder(String name) {
    final String lower = name.toLowerCase();

    if (commonSourceFolders.contains(lower)) {
      return FolderType.source;
    }

    if (commonExtraFolders.contains(lower)) {
      return FolderType.extra;
    }

    return FolderType.other;
  }

  /// Check if a directory contains any files (not just subdirectories)
  static Future<bool> _hasRelevantFiles(Directory dir) async {
    try {
      await for (final FileSystemEntity entity in dir.list(recursive: true)) {
        if (entity is File) {
          final String ext = p.extension(entity.path).toLowerCase();
          // Check for common code file extensions
          if (_isCodeFile(ext)) {
            return true;
          }
        }
      }
    } catch (e) {
      // Ignore permission errors, etc.
    }
    return false;
  }

  /// Check if extension is a known code file type
  static bool _isCodeFile(String ext) {
    const Set<String> codeExtensions = {
      '.dart', '.py', '.pyw', '.pyi',
      '.js', '.jsx', '.mjs', '.cjs', '.ts', '.tsx', '.mts', '.cts',
      '.go', '.rs', '.java', '.kt', '.kts', '.swift',
      '.c', '.cpp', '.cc', '.h', '.hpp', '.cs',
      '.rb', '.rake', '.gemspec', '.php', '.phtml',
      '.html', '.css', '.scss', '.sass', '.less',
      '.vue', '.svelte', '.json', '.yaml', '.yml',
      '.sh', '.bash', '.zsh', '.ps1', '.bat', '.cmd',
      '.sql', '.graphql', '.gql', '.proto',
      '.md', '.txt', '.xml', '.toml',
    };
    return codeExtensions.contains(ext);
  }

  /// Get a suggested suffix for a folder name
  static String? getSuggestedSuffix(String folderName) {
    final String lower = folderName.toLowerCase();

    // Source folders don't need a suffix
    if (commonSourceFolders.contains(lower)) {
      return null;
    }

    // Use the folder name as suffix for extras
    return lower;
  }
}

/// A detected folder with classification
class DetectedFolder {
  final String path;
  final FolderType type;
  final bool suggested;

  const DetectedFolder({
    required this.path,
    required this.type,
    this.suggested = false,
  });

  String get typeLabel {
    switch (type) {
      case FolderType.source:
        return 'source';
      case FolderType.extra:
        return 'extra';
      case FolderType.other:
        return 'other';
    }
  }
}

/// Classification of folder types
enum FolderType {
  source, // Main source folders (lib, src)
  extra,  // Common extra folders (dev, test, scripts)
  other,  // Other folders
}
