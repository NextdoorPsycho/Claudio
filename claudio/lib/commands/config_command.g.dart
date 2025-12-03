// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_command.dart';

// **************************************************************************
// SubcommandGenerator
// **************************************************************************

class _$ConfigCommand<T extends dynamic> extends Command<dynamic> {
  _$ConfigCommand() {
    final upcastedType = (this as ConfigCommand);
    addSubcommand(InitCommand(upcastedType.init));
    addSubcommand(GetCommand(upcastedType.get));
    addSubcommand(SetCommand(upcastedType.set));
    addSubcommand(ListCommand(upcastedType.list));
    addSubcommand(PathCommand(upcastedType.path));
  }

  @override
  String get name => 'config';

  @override
  String get description => 'Configuration management commands';
}

class InitCommand extends Command<void> {
  InitCommand(this.userMethod) {
    argParser.addFlag(
      'force',
      defaultsTo: false,
    );
  }

  final Future<void> Function({bool force}) userMethod;

  @override
  String get name => 'init';

  @override
  String get description => 'Initialize configuration file with default values';

  @override
  Future<void> run() {
    final results = argResults!;
    return userMethod(force: (results['force'] as bool?) ?? false);
  }
}

class GetCommand extends Command<void> {
  GetCommand(this.userMethod) {
    argParser.addOption(
      'key',
      mandatory: true,
    );
  }

  final Future<void> Function(String) userMethod;

  @override
  String get name => 'get';

  @override
  String get description => 'Get a configuration value by key';

  @override
  Future<void> run() {
    final results = argResults!;
    var [String key] = results.rest;
    return userMethod(key);
  }
}

class SetCommand extends Command<void> {
  SetCommand(this.userMethod) {
    argParser
      ..addOption(
        'key',
        mandatory: true,
      )
      ..addOption(
        'value',
        mandatory: true,
      );
  }

  final Future<void> Function(
    String,
    String,
  ) userMethod;

  @override
  String get name => 'set';

  @override
  String get description => 'Set a configuration value';

  @override
  Future<void> run() {
    final results = argResults!;
    var [
      String key,
      String value,
    ] = results.rest;
    return userMethod(
      key,
      value,
    );
  }
}

class ListCommand extends Command<void> {
  ListCommand(this.userMethod);

  final Future<void> Function() userMethod;

  @override
  String get name => 'list';

  @override
  String get description => 'List all configuration values';

  @override
  Future<void> run() {
    return userMethod();
  }
}

class PathCommand extends Command<void> {
  PathCommand(this.userMethod);

  final Future<void> Function() userMethod;

  @override
  String get name => 'path';

  @override
  String get description => 'Show configuration file path';

  @override
  Future<void> run() {
    return userMethod();
  }
}
