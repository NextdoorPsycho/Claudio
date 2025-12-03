# Claudio

A universal CLI tool that bundles source files into chunked output files optimized for LLM context windows.

> *no relation to claude — I just like the name Claudio, and I want to immortalize it.*

## What it does

Claudio scans your project, intelligently filters out generated files and noise, optionally strips comments, and combines everything into neatly chunked output files that fit within LLM token limits. Perfect for feeding your entire codebase to an AI assistant.

## Features

- **Universal language support** — Dart, Python, JavaScript, TypeScript, Go, Rust, Java, Kotlin, Swift, C/C++, C#, Ruby, PHP, and web projects
- **Smart detection** — Auto-detects project type and applies language-specific ignore patterns
- **Multiple output formats** — Plain text, Markdown with syntax highlighting, or JSON with metadata
- **Comment stripping** — Optionally removes comments to maximize content density
- **Chunked output** — Splits large codebases into manageable files (default 1MB each)
- **Watch mode** — Auto-regenerates when source files change
- **Profiles** — Save and reuse configuration presets
- **Interactive wizard** — Guided setup when run without arguments

## Installation

```bash
# Clone the repository
git clone https://github.com/NextdoorPsycho/Claudio.git
cd Claudio/claudio

# Install dependencies
dart pub get

# Generate CLI code
dart run build_runner build --delete-conflicting-outputs

# Option 1: Run directly
dart run bin/main.dart

# Option 2: Install globally
dart pub global activate . --source=path
claudio
```

## Usage

### Interactive Wizard

Just run `claudio` with no arguments for a guided experience:

```
  ╔═════════════════════════════════════════════════╗
  ║       _____ _                 _ _               ║
  ║      / ____| |               | (_)              ║
  ║     | |    | | __ _ _   _  __| |_  ___          ║
  ║     | |    | |/ _` | | | |/ _` | |/ _ \         ║
  ║     | |____| | (_| | |_| | (_| | | (_) |        ║
  ║      \_____|_|\__,_|\__,_|\__,_|_|\___/         ║
  ║                                                 ║
  ║  Universal source bundler for LLM consumption   ║
  ║  no relation to claude                          ║
  ╚═════════════════════════════════════════════════╝

  1. 📦  Generate   - Bundle source files for LLM consumption
  2. 👁  Watch      - Auto-regenerate when files change
  3. ⚙  Init       - Create a .claudio.yaml config file
  4. 💾  Profiles   - Manage saved configuration profiles
  5. ❓  Help       - Show help and documentation
  6. 👋  Exit       - Exit the wizard
```

### Command Line

```bash
# Generate with auto-detected settings
claudio gen run

# Skip confirmation prompts
claudio gen run --yes

# Specify project type and source
claudio gen run --type python --source src

# Generate markdown output
claudio gen run --format markdown

# Watch mode (auto-regenerate on changes)
claudio gen watch

# Initialize a config file
claudio gen init

# List supported project types
claudio gen types

# Save a profile
claudio gen profile save myproject --type dart

# Use a saved profile
claudio gen run --profile myproject
```

### Options

| Flag | Description |
|------|-------------|
| `--source, -s` | Source directory to scan |
| `--type, -t` | Project type (dart, python, typescript, etc.) |
| `--prefix, -p` | Output file prefix (default: CLAUDIO) |
| `--max-size` | Max output file size in KB (default: 1000) |
| `--format, -f` | Output format: text, markdown, or json |
| `--profile` | Load settings from a saved profile |
| `--yes, -y` | Skip confirmation prompts |
| `--verbose, -v` | Show detailed output |

## Supported Languages

| Type | Extensions | Comment Style |
|------|------------|---------------|
| dart | `.dart` | `//` `/* */` |
| python | `.py` `.pyw` `.pyi` | `#` `""" """` |
| javascript | `.js` `.jsx` `.mjs` `.cjs` | `//` `/* */` |
| typescript | `.ts` `.tsx` `.mts` `.cts` | `//` `/* */` |
| go | `.go` | `//` `/* */` |
| rust | `.rs` | `//` `/* */` |
| java | `.java` | `//` `/* */` |
| kotlin | `.kt` `.kts` | `//` `/* */` |
| swift | `.swift` | `//` `/* */` |
| cpp | `.c` `.cpp` `.cc` `.h` `.hpp` | `//` `/* */` |
| csharp | `.cs` | `//` `/* */` |
| ruby | `.rb` `.rake` `.gemspec` | `#` |
| php | `.php` `.phtml` | `//` `/* */` |
| web | `.html` `.css` `.scss` `.vue` `.svelte` | Mixed |
| generic | `.txt` `.md` `.json` `.yaml` `.sh` | `#` |

## Configuration

Create a `.claudio.yaml` in your project root:

```yaml
project_type: dart
source_dir: lib
output_prefix: CLAUDIO
target_size_kb: 1000
remove_comments: true
output_format: text

# Additional ignore patterns
ignore_patterns:
  - "*.generated.dart"
  - "test/**"

# Extra files to include from root
extra_root_files:
  - pubspec.yaml
  - README.md
```

## Output Example

**Text format** (default):
```
// File: lib/main.dart
void main() {
  print('Hello, World!');
}

// File: lib/utils/helper.dart
String formatName(String name) => name.toUpperCase();
```

**Markdown format**:
````markdown
# Code Bundle - Part 001

## lib/main.dart

```dart
void main() {
  print('Hello, World!');
}
```
````

## License

GNUv3
