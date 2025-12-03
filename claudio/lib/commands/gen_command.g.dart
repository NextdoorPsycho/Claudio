// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gen_command.dart';

// **************************************************************************
// SubcommandGenerator
// **************************************************************************

class _$GenCommand<T extends dynamic> extends Command<dynamic> {
  _$GenCommand() {
    final upcastedType = (this as GenCommand);
    addSubcommand(RunCommand(upcastedType.run));
    addSubcommand(WatchCommand(upcastedType.watch));
    addSubcommand(InitCommand(upcastedType.init));
    addSubcommand(TypesCommand(upcastedType.types));
    addSubcommand(upcastedType.profile);
  }

  @override
  String get name => 'gen';

  @override
  String get description =>
      'Generate combined source files for LLM consumption';
}

class RunCommand extends Command<void> {
  RunCommand(this.userMethod) {
    argParser
      ..addOption(
        'source',
        mandatory: false,
      )
      ..addOption(
        'type',
        mandatory: false,
      )
      ..addOption(
        'prefix',
        mandatory: false,
      )
      ..addOption(
        'max-size',
        mandatory: false,
      )
      ..addFlag('remove-comments')
      ..addOption(
        'format',
        mandatory: false,
      )
      ..addOption(
        'profile',
        mandatory: false,
      )
      ..addFlag(
        'yes',
        defaultsTo: false,
      )
      ..addFlag(
        'verbose',
        defaultsTo: false,
      );
  }

  final Future<void> Function({
    String? source,
    String? type,
    String? prefix,
    int? maxSize,
    bool? removeComments,
    String? format,
    String? profile,
    bool yes,
    bool verbose,
  }) userMethod;

  @override
  String get name => 'run';

  @override
  String get description => 'Generate combined output files from source code';

  @override
  Future<void> run() {
    final results = argResults!;
    return userMethod(
      source: (results['source'] as String?) ?? null,
      type: (results['type'] as String?) ?? null,
      prefix: (results['prefix'] as String?) ?? null,
      maxSize:
          results['max-size'] != null ? int.parse(results['max-size']) : null,
      removeComments: (results['remove-comments'] as bool?) ?? null,
      format: (results['format'] as String?) ?? null,
      profile: (results['profile'] as String?) ?? null,
      yes: (results['yes'] as bool?) ?? false,
      verbose: (results['verbose'] as bool?) ?? false,
    );
  }
}

class WatchCommand extends Command<void> {
  WatchCommand(this.userMethod) {
    argParser
      ..addOption(
        'source',
        mandatory: false,
      )
      ..addOption(
        'type',
        mandatory: false,
      )
      ..addOption(
        'prefix',
        mandatory: false,
      )
      ..addOption(
        'max-size',
        mandatory: false,
      )
      ..addFlag('remove-comments')
      ..addOption(
        'format',
        mandatory: false,
      )
      ..addOption(
        'profile',
        mandatory: false,
      )
      ..addFlag(
        'verbose',
        defaultsTo: false,
      );
  }

  final Future<void> Function({
    String? source,
    String? type,
    String? prefix,
    int? maxSize,
    bool? removeComments,
    String? format,
    String? profile,
    bool verbose,
  }) userMethod;

  @override
  String get name => 'watch';

  @override
  String get description =>
      'Watch mode - auto-regenerate when source files change';

  @override
  Future<void> run() {
    final results = argResults!;
    return userMethod(
      source: (results['source'] as String?) ?? null,
      type: (results['type'] as String?) ?? null,
      prefix: (results['prefix'] as String?) ?? null,
      maxSize:
          results['max-size'] != null ? int.parse(results['max-size']) : null,
      removeComments: (results['remove-comments'] as bool?) ?? null,
      format: (results['format'] as String?) ?? null,
      profile: (results['profile'] as String?) ?? null,
      verbose: (results['verbose'] as bool?) ?? false,
    );
  }
}

class InitCommand extends Command<void> {
  InitCommand(this.userMethod) {
    argParser
      ..addOption(
        'type',
        mandatory: false,
      )
      ..addFlag(
        'force',
        defaultsTo: false,
      );
  }

  final Future<void> Function({
    String? type,
    bool force,
  }) userMethod;

  @override
  String get name => 'init';

  @override
  String get description => 'Initialize a project-local configuration file';

  @override
  Future<void> run() {
    final results = argResults!;
    return userMethod(
      type: (results['type'] as String?) ?? null,
      force: (results['force'] as bool?) ?? false,
    );
  }
}

class TypesCommand extends Command<void> {
  TypesCommand(this.userMethod);

  final Future<void> Function() userMethod;

  @override
  String get name => 'types';

  @override
  String get description => 'List supported project types';

  @override
  Future<void> run() {
    return userMethod();
  }
}

class _$ProfileCommand<T extends dynamic> extends Command<dynamic> {
  _$ProfileCommand() {
    final upcastedType = (this as ProfileCommand);
    addSubcommand(SaveCommand(upcastedType.save));
    addSubcommand(ShowCommand(upcastedType.show));
    addSubcommand(ListCommand(upcastedType.list));
    addSubcommand(DeleteCommand(upcastedType.delete));
  }

  @override
  String get name => 'profile';

  @override
  String get description => 'Profile management subcommand';
}

class SaveCommand extends Command<void> {
  SaveCommand(this.userMethod) {
    argParser
      ..addOption(
        'name',
        mandatory: true,
      )
      ..addOption(
        'source',
        mandatory: false,
      )
      ..addOption(
        'type',
        mandatory: false,
      )
      ..addOption(
        'prefix',
        mandatory: false,
      )
      ..addOption(
        'max-size',
        mandatory: false,
      )
      ..addFlag(
        'remove-comments',
        defaultsTo: true,
      )
      ..addOption(
        'format',
        defaultsTo: 'text',
        mandatory: false,
      );
  }

  final Future<void> Function(
    String, {
    String? source,
    String? type,
    String? prefix,
    int? maxSize,
    bool removeComments,
    String format,
  }) userMethod;

  @override
  String get name => 'save';

  @override
  String get description => 'Save current settings as a named profile';

  @override
  Future<void> run() {
    final results = argResults!;
    var [String name] = results.rest;
    return userMethod(
      name,
      source: (results['source'] as String?) ?? null,
      type: (results['type'] as String?) ?? null,
      prefix: (results['prefix'] as String?) ?? null,
      maxSize:
          results['max-size'] != null ? int.parse(results['max-size']) : null,
      removeComments: (results['remove-comments'] as bool?) ?? true,
      format: (results['format'] as String?) ?? 'text',
    );
  }
}

class ShowCommand extends Command<void> {
  ShowCommand(this.userMethod) {
    argParser.addOption(
      'name',
      mandatory: true,
    );
  }

  final Future<void> Function(String) userMethod;

  @override
  String get name => 'show';

  @override
  String get description => 'Show details of a saved profile';

  @override
  Future<void> run() {
    final results = argResults!;
    var [String name] = results.rest;
    return userMethod(name);
  }
}

class ListCommand extends Command<void> {
  ListCommand(this.userMethod);

  final Future<void> Function() userMethod;

  @override
  String get name => 'list';

  @override
  String get description => 'List all saved profiles';

  @override
  Future<void> run() {
    return userMethod();
  }
}

class DeleteCommand extends Command<void> {
  DeleteCommand(this.userMethod) {
    argParser.addOption(
      'name',
      mandatory: true,
    );
  }

  final Future<void> Function(String) userMethod;

  @override
  String get name => 'delete';

  @override
  String get description => 'Delete a saved profile';

  @override
  Future<void> run() {
    final results = argResults!;
    var [String name] = results.rest;
    return userMethod(name);
  }
}
