import 'dart:io';

/// Supported project/language types
enum ProjectType {
  /// Auto-detect based on project files
  auto,

  /// Dart/Flutter projects
  dart,

  /// Python projects
  python,

  /// JavaScript projects
  javascript,

  /// TypeScript projects
  typescript,

  /// Go projects
  go,

  /// Rust projects
  rust,

  /// Java projects
  java,

  /// Kotlin projects
  kotlin,

  /// Swift projects
  swift,

  /// C/C++ projects
  cpp,

  /// C# projects
  csharp,

  /// Ruby projects
  ruby,

  /// PHP projects
  php,

  /// Web projects (HTML/CSS/JS)
  web,

  /// Generic (all text files)
  generic,
}

/// Comment style for different languages
enum CommentStyle {
  /// C-style: // and /* */
  cStyle,

  /// Python-style: # and """ """
  pythonStyle,

  /// Hash-style: # only
  hashStyle,

  /// HTML-style: <!-- -->
  htmlStyle,

  /// Mixed web: supports HTML, CSS, and JS comments
  mixedWeb,
}

/// Configuration for a specific language/project type
class LanguageConfig {
  /// Project type
  final ProjectType type;

  /// File extensions to include (e.g., ['.dart', '.py'])
  final List<String> extensions;

  /// Comment style name (serializable version of CommentStyle)
  final String commentStyleName;

  /// Default ignore patterns for this language
  final List<String> defaultIgnorePatterns;

  /// Default source directories to scan
  final List<String> defaultSourceDirs;

  const LanguageConfig({
    required this.type,
    required this.extensions,
    required this.commentStyleName,
    this.defaultIgnorePatterns = const [],
    this.defaultSourceDirs = const ['.'],
  });

  /// Get the CommentStyle enum value
  CommentStyle get commentStyle => CommentStyle.values.firstWhere(
        (s) => s.name == commentStyleName,
        orElse: () => CommentStyle.cStyle,
      );

  /// Get language config for a project type
  static LanguageConfig forType(ProjectType type) {
    return configs[type] ?? configs[ProjectType.generic]!;
  }

  /// Auto-detect project type from directory
  static ProjectType detectProjectType(String directory) {
    final checks = {
      'pubspec.yaml': ProjectType.dart,
      'requirements.txt': ProjectType.python,
      'pyproject.toml': ProjectType.python,
      'setup.py': ProjectType.python,
      'Pipfile': ProjectType.python,
      'package.json': ProjectType.javascript,
      'tsconfig.json': ProjectType.typescript,
      'go.mod': ProjectType.go,
      'Cargo.toml': ProjectType.rust,
      'pom.xml': ProjectType.java,
      'build.gradle': ProjectType.java,
      'build.gradle.kts': ProjectType.kotlin,
      'Package.swift': ProjectType.swift,
      'CMakeLists.txt': ProjectType.cpp,
      'Gemfile': ProjectType.ruby,
      'composer.json': ProjectType.php,
      'index.html': ProjectType.web,
    };

    for (final entry in checks.entries) {
      final file = File('$directory/${entry.key}');
      if (file.existsSync()) {
        return entry.value;
      }
    }

    return ProjectType.generic;
  }

  /// All predefined language configurations
  static final Map<ProjectType, LanguageConfig> configs = {
    ProjectType.dart: const LanguageConfig(
      type: ProjectType.dart,
      extensions: ['.dart'],
      commentStyleName: 'cStyle',
      defaultIgnorePatterns: [
        '*.g.dart',
        '*.freezed.dart',
        '*.gr.dart',
        '*.artifact.dart',
        '*/generated/*',
        '.dart_tool/*',
        'build/*',
      ],
      defaultSourceDirs: ['lib', 'bin', 'src'],
    ),
    ProjectType.python: const LanguageConfig(
      type: ProjectType.python,
      extensions: ['.py', '.pyw', '.pyi'],
      commentStyleName: 'pythonStyle',
      defaultIgnorePatterns: [
        '__pycache__/*',
        '*.pyc',
        '.venv/*',
        'venv/*',
        '.env/*',
        'env/*',
        '*.egg-info/*',
        'dist/*',
        'build/*',
        '.tox/*',
        '.pytest_cache/*',
      ],
      defaultSourceDirs: ['src', '.'],
    ),
    ProjectType.javascript: const LanguageConfig(
      type: ProjectType.javascript,
      extensions: ['.js', '.jsx', '.mjs', '.cjs'],
      commentStyleName: 'cStyle',
      defaultIgnorePatterns: [
        'node_modules/*',
        'dist/*',
        'build/*',
        '*.min.js',
        '*.bundle.js',
        'coverage/*',
        '.next/*',
        '.nuxt/*',
      ],
      defaultSourceDirs: ['src', 'lib', '.'],
    ),
    ProjectType.typescript: const LanguageConfig(
      type: ProjectType.typescript,
      extensions: ['.ts', '.tsx', '.mts', '.cts'],
      commentStyleName: 'cStyle',
      defaultIgnorePatterns: [
        'node_modules/*',
        'dist/*',
        'build/*',
        '*.d.ts',
        '*.js.map',
        'coverage/*',
        '.next/*',
        '.nuxt/*',
      ],
      defaultSourceDirs: ['src', 'lib', '.'],
    ),
    ProjectType.go: const LanguageConfig(
      type: ProjectType.go,
      extensions: ['.go'],
      commentStyleName: 'cStyle',
      defaultIgnorePatterns: [
        'vendor/*',
        '*_test.go',
        '*.pb.go',
        'bin/*',
      ],
      defaultSourceDirs: ['cmd', 'pkg', 'internal', '.'],
    ),
    ProjectType.rust: const LanguageConfig(
      type: ProjectType.rust,
      extensions: ['.rs'],
      commentStyleName: 'cStyle',
      defaultIgnorePatterns: [
        'target/*',
        '*.rlib',
      ],
      defaultSourceDirs: ['src'],
    ),
    ProjectType.java: const LanguageConfig(
      type: ProjectType.java,
      extensions: ['.java'],
      commentStyleName: 'cStyle',
      defaultIgnorePatterns: [
        'target/*',
        'build/*',
        '*.class',
        '.gradle/*',
        'out/*',
      ],
      defaultSourceDirs: ['src/main/java', 'src'],
    ),
    ProjectType.kotlin: const LanguageConfig(
      type: ProjectType.kotlin,
      extensions: ['.kt', '.kts'],
      commentStyleName: 'cStyle',
      defaultIgnorePatterns: [
        'target/*',
        'build/*',
        '*.class',
        '.gradle/*',
        'out/*',
      ],
      defaultSourceDirs: ['src/main/kotlin', 'src'],
    ),
    ProjectType.swift: const LanguageConfig(
      type: ProjectType.swift,
      extensions: ['.swift'],
      commentStyleName: 'cStyle',
      defaultIgnorePatterns: [
        '.build/*',
        'DerivedData/*',
        '*.xcodeproj/*',
        'Pods/*',
      ],
      defaultSourceDirs: ['Sources', 'src', '.'],
    ),
    ProjectType.cpp: const LanguageConfig(
      type: ProjectType.cpp,
      extensions: ['.c', '.cpp', '.cc', '.cxx', '.h', '.hpp', '.hxx'],
      commentStyleName: 'cStyle',
      defaultIgnorePatterns: [
        'build/*',
        'cmake-build-*/*',
        '*.o',
        '*.a',
        '*.so',
        '*.dylib',
        '*.exe',
      ],
      defaultSourceDirs: ['src', 'include', '.'],
    ),
    ProjectType.csharp: const LanguageConfig(
      type: ProjectType.csharp,
      extensions: ['.cs'],
      commentStyleName: 'cStyle',
      defaultIgnorePatterns: [
        'bin/*',
        'obj/*',
        '*.Designer.cs',
        '*.g.cs',
        'packages/*',
      ],
      defaultSourceDirs: ['src', '.'],
    ),
    ProjectType.ruby: const LanguageConfig(
      type: ProjectType.ruby,
      extensions: ['.rb', '.rake', '.gemspec'],
      commentStyleName: 'hashStyle',
      defaultIgnorePatterns: [
        'vendor/*',
        '.bundle/*',
        'coverage/*',
        'tmp/*',
        'log/*',
      ],
      defaultSourceDirs: ['lib', 'app', 'src', '.'],
    ),
    ProjectType.php: const LanguageConfig(
      type: ProjectType.php,
      extensions: ['.php', '.phtml'],
      commentStyleName: 'cStyle',
      defaultIgnorePatterns: [
        'vendor/*',
        'node_modules/*',
        'cache/*',
        'storage/*',
        'bootstrap/cache/*',
      ],
      defaultSourceDirs: ['src', 'app', 'lib', '.'],
    ),
    ProjectType.web: const LanguageConfig(
      type: ProjectType.web,
      extensions: ['.html', '.htm', '.css', '.scss', '.sass', '.less', '.js', '.vue', '.svelte'],
      commentStyleName: 'mixedWeb',
      defaultIgnorePatterns: [
        'node_modules/*',
        'dist/*',
        'build/*',
        '*.min.js',
        '*.min.css',
        'public/*',
      ],
      defaultSourceDirs: ['src', '.'],
    ),
    ProjectType.generic: const LanguageConfig(
      type: ProjectType.generic,
      extensions: [
        '.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.toml',
        '.cfg', '.ini', '.conf', '.sh', '.bash', '.zsh', '.fish',
      ],
      commentStyleName: 'hashStyle',
      defaultIgnorePatterns: [
        '.git/*',
        '.svn/*',
        '.hg/*',
        'node_modules/*',
        '__pycache__/*',
        '.idea/*',
        '.vscode/*',
        '.DS_Store',
        'Thumbs.db',
      ],
      defaultSourceDirs: ['.'],
    ),
  };
}
