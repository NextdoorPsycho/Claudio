// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claudio.dart';

// **************************************************************************
// CliRunnerGenerator
// **************************************************************************

const String version = '1.0.0';

/// Claudio CLI - Combine Dart files for LLM consumption
///
/// A class for invoking [Command]s based on raw command-line arguments.
///
/// The type argument `T` represents the type returned by [Command.run] and
/// [CommandRunner.run]; it can be ommitted if you're not using the return
/// values.
class _$ClaudioRunner<T extends dynamic> extends CommandRunner<dynamic> {
  _$ClaudioRunner()
      : super(
          'claudio',
          'Claudio CLI - Combine Dart files for LLM consumption',
        ) {
    final upcastedType = (this as ClaudioRunner);
    addCommand(upcastedType.gen);
    addCommand(upcastedType.config);

    argParser.addFlag(
      'version',
      help: 'Reports the version of this tool.',
    );
  }

  @override
  Future<dynamic> runCommand(ArgResults topLevelResults) async {
    try {
      if (topLevelResults['version'] == true) {
        return showVersion();
      }

      return await super.runCommand(topLevelResults);
    } on UsageException catch (e) {
      stdout.writeln('${e.message}\n');
      stdout.writeln(e.usage);
    }
  }

  void showVersion() {
    return stdout.writeln('claudio $version');
  }
}
