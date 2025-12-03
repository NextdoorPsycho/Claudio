import 'dart:io';
import 'package:fast_log/fast_log.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../models/gen_config.dart';

/// Service for managing saved profiles
class ProfileManager {
  final String profilesDir;

  ProfileManager(this.profilesDir);

  /// Create a ProfileManager with the default profiles directory
  factory ProfileManager.withDefaults() {
    return ProfileManager(GenConfig.profilesDir);
  }

  /// Get the path for a profile file
  String _getProfilePath(String name) {
    // Sanitize name to prevent path traversal
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return p.join(profilesDir, '$safeName.yaml');
  }

  /// Check if a profile exists
  Future<bool> profileExists(String name) async {
    final file = File(_getProfilePath(name));
    return file.exists();
  }

  /// Save a configuration as a named profile
  Future<void> saveProfile(String name, GenConfig config) async {
    final dir = Directory(profilesDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File(_getProfilePath(name));
    await file.writeAsString(config.toYaml());

    if (config.verbose) {
      verbose('Profile saved to: ${file.path}');
    }
  }

  /// Load a profile by name
  Future<GenConfig> loadProfile(String name) async {
    final file = File(_getProfilePath(name));

    if (!await file.exists()) {
      throw FileSystemException('Profile not found: $name', file.path);
    }

    final content = await file.readAsString();
    final yaml = loadYaml(content);

    if (yaml is! Map) {
      throw FormatException('Invalid profile format: $name');
    }

    return GenConfig.fromYaml(yaml);
  }

  /// List all saved profiles
  Future<List<ProfileInfo>> listProfiles() async {
    final dir = Directory(profilesDir);

    if (!await dir.exists()) {
      return [];
    }

    final profiles = <ProfileInfo>[];

    await for (final FileSystemEntity entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.yaml')) {
        final name = p.basenameWithoutExtension(entity.path);
        final stat = await entity.stat();

        try {
          final config = await loadProfile(name);
          profiles.add(ProfileInfo(
            name: name,
            path: entity.path,
            lastModified: stat.modified,
            config: config,
          ));
        } catch (e) {
          // Skip invalid profiles
          warn('Skipping invalid profile: $name ($e)');
        }
      }
    }

    // Sort by name
    profiles.sort((ProfileInfo a, ProfileInfo b) => a.name.compareTo(b.name));
    return profiles;
  }

  /// Delete a profile
  Future<void> deleteProfile(String name) async {
    final file = File(_getProfilePath(name));

    if (!await file.exists()) {
      throw FileSystemException('Profile not found: $name', file.path);
    }

    await file.delete();
  }

  /// Load project-local config from .claudio.yaml in working directory
  Future<GenConfig?> loadProjectConfig([String? workingDir]) async {
    final dir = workingDir ?? Directory.current.path;
    final file = File(p.join(dir, '.claudio.yaml'));

    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final yaml = loadYaml(content);

      if (yaml is! Map) {
        return null;
      }

      return GenConfig.fromYaml(yaml);
    } catch (e) {
      warn('Could not load project config: $e');
      return null;
    }
  }

  /// Save project-local config to .claudio.yaml
  Future<void> saveProjectConfig(GenConfig config, [String? workingDir]) async {
    final dir = workingDir ?? Directory.current.path;
    final file = File(p.join(dir, '.claudio.yaml'));

    await file.writeAsString(config.toYaml());
  }
}

/// Information about a saved profile
class ProfileInfo {
  final String name;
  final String path;
  final DateTime lastModified;
  final GenConfig config;

  const ProfileInfo({
    required this.name,
    required this.path,
    required this.lastModified,
    required this.config,
  });

  @override
  String toString() => 'ProfileInfo($name)';
}
