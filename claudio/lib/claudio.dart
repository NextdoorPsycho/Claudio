import 'package:cli_annotations/cli_annotations.dart';
import 'package:fast_log/fast_log.dart';

import 'commands/config_command.dart';
import 'commands/gen_command.dart';

part 'claudio.g.dart';

/// Claudio CLI - Combine Dart files for LLM consumption
///
/// This CLI tool scans Dart projects and combines source files into
/// chunked output files suitable for LLM context windows.
@cliRunner
class ClaudioRunner extends _$ClaudioRunner {
  ClaudioRunner() {
    verbose("ClaudioRunner initialized");
  }

  /// Generate combined Dart files for LLM consumption
  @cliMount
  GenCommand get gen => GenCommand();

  /// Configuration management commands
  @cliMount
  ConfigCommand get config => ConfigCommand();
}
