## 1.2.0

### Added
- **Multi-Folder Mode** - Process multiple source folders with separate outputs
  - Each folder generates its own output files (e.g., `CLAUDIO_dev-001.txt`)
  - Interactive folder detection and selection in wizard
  - Custom suffix naming for each folder
  - New `SourceFolder` model for folder configuration
  - New `FolderDetector` utility for smart folder discovery
  - New `MultiSourceProcessor` service for orchestrating multi-folder builds
- **All Files Mode** - Scan ALL supported file types regardless of project type
  - Includes 40+ file extensions across all languages
  - Output prefix `CLAUDIO_ALL` by default
  - Useful for mixed-language or polyglot projects
- New wizard menu options:
  - "Multi-Folder" - Process multiple folders with separate outputs
  - "All Files" - Scan all supported file types in project
- `GenConfig` enhancements:
  - `sourceFolders` field for multi-folder configuration
  - `allFilesMode` flag for all-files scanning
  - `allSupportedExtensions` static list of all known extensions
  - `isMultiFolderMode` and `enabledSourceFolders` getters

### Changed
- Made `UserPrompt.makeProgressBar()` public for reuse
- Updated wizard to support 8 menu options (was 6)
- **Output prefix now defaults to parent folder name** instead of hardcoded "CLAUDIO"
  - Wizard always prompts for output prefix before generation
  - Prefix is uppercased and sanitized (non-alphanumeric chars become underscores)
  - Applies to all wizard flows: Generate, Multi-Folder, and All Files modes

## 1.1.0

### Added
- Interactive wizard when running `claudio` with no arguments
  - ASCII art banner with colored output
  - Menu-driven interface for Generate, Watch, Init, Profiles, and Help
  - Step-by-step configuration with smart defaults
- Comprehensive README documentation in parent directory

### Changed
- Strongly-typed entire codebase (44 typing improvements)
  - Explicit types for all loop variables, lambda parameters, and collections
  - Added `FileSystemEntity` types to async iterators
  - Typed all `fold`, `map`, and `sort` callbacks
- Updated `analysis_options.yaml` with strict mode
  - Enabled `strict-casts` and `strict-inference`
  - Added linter rules: `always_declare_return_types`, `annotate_overrides`, `avoid_dynamic_calls`, `prefer_final_locals`, `prefer_const_constructors`, `prefer_const_declarations`
  - Excluded generated `*.g.dart` files from analysis

### Fixed
- Removed unused imports in `file_processor.dart` and `output_generator.dart`
- Removed unnecessary `library claudio;` declaration
- Added missing `@override` annotation on `GenCommand.run()`
- Fixed untyped `StreamSubscription` in `file_watcher.dart`
- Added `const` constructors where applicable

## 1.0.0

- Initial version.
