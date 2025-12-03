import 'dart:convert';
import 'dart:io';
import 'package:fast_log/fast_log.dart';
import 'package:path/path.dart' as p;

import '../models/gen_config.dart';
import '../models/file_info.dart';

/// Service for generating output files in various formats
class OutputGenerator {
  final GenConfig config;
  final String outputDir;

  OutputGenerator(this.config, this.outputDir);

  /// Chunk files by size limit
  List<List<FileInfo>> chunkFilesBySize(List<FileInfo> files) {
    final List<List<FileInfo>> chunks = <List<FileInfo>>[];
    List<FileInfo> currentChunk = <FileInfo>[];
    int currentSize = 0;
    final maxSize = config.targetSizeKB * 1024;

    for (final file in files) {
      final fileSize = file.contentSize;

      // If adding this file would exceed the limit, start a new chunk
      // (unless the current chunk is empty - we need at least one file per chunk)
      if (currentChunk.isNotEmpty && currentSize + fileSize > maxSize) {
        chunks.add(currentChunk);
        currentChunk = <FileInfo>[];
        currentSize = 0;
      }

      currentChunk.add(file);
      currentSize += fileSize;
    }

    // Don't forget the last chunk
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
    }

    return chunks;
  }

  /// Generate all output files
  Future<List<String>> generateOutputs(
    List<FileInfo> files, {
    void Function(String path)? onFileCreated,
  }) async {
    if (files.isEmpty) {
      warn('No files to generate output from');
      return [];
    }

    final chunks = chunkFilesBySize(files);
    final outputPaths = <String>[];

    for (int i = 0; i < chunks.length; i++) {
      final partNumber = i + 1;
      final chunk = chunks[i];

      final outputPath = await _generateChunkOutput(chunk, partNumber);
      outputPaths.add(outputPath);
      onFileCreated?.call(outputPath);
    }

    return outputPaths;
  }

  /// Generate output for a single chunk
  Future<String> _generateChunkOutput(List<FileInfo> chunk, int partNumber) async {
    final extension = _getExtension();
    final fileName = '${config.outputPrefix}-${partNumber.toString().padLeft(3, '0')}.$extension';
    final outputPath = p.join(outputDir, fileName);

    String content;
    switch (config.outputFormat) {
      case OutputFormat.text:
        content = _generateTextContent(chunk, partNumber);
        break;
      case OutputFormat.markdown:
        content = _generateMarkdownContent(chunk, partNumber);
        break;
      case OutputFormat.json:
        content = _generateJsonContent(chunk, partNumber);
        break;
    }

    final file = File(outputPath);
    await file.writeAsString(content);

    if (config.verbose) {
      verbose('Created: $fileName (${chunk.length} files, ${content.length} bytes)');
    }

    return outputPath;
  }

  String _getExtension() {
    switch (config.outputFormat) {
      case OutputFormat.text:
        return 'txt';
      case OutputFormat.markdown:
        return 'md';
      case OutputFormat.json:
        return 'json';
    }
  }

  /// Generate text format (original bash script style)
  String _generateTextContent(List<FileInfo> chunk, int partNumber) {
    final buffer = StringBuffer();

    for (final file in chunk) {
      buffer.writeln('// File: ${file.relativePath}');
      buffer.writeln(file.content);
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generate markdown format with syntax highlighting
  String _generateMarkdownContent(List<FileInfo> chunk, int partNumber) {
    final buffer = StringBuffer();

    buffer.writeln('# Code Bundle - Part ${partNumber.toString().padLeft(3, '0')}');
    buffer.writeln();
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Table of contents
    buffer.writeln('## Table of Contents');
    buffer.writeln();
    for (int i = 0; i < chunk.length; i++) {
      final file = chunk[i];
      final anchor = _makeAnchor(file.relativePath);
      buffer.writeln('${i + 1}. [${file.relativePath}](#$anchor)');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // File contents
    for (final file in chunk) {
      buffer.writeln('## ${file.relativePath}');
      buffer.writeln();
      buffer.writeln('```dart');
      buffer.writeln(file.content);
      buffer.writeln('```');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generate JSON format with metadata
  String _generateJsonContent(List<FileInfo> chunk, int partNumber) {
    final Map<String, Object> data = {
      'part': partNumber,
      'generated': DateTime.now().toIso8601String(),
      'config': {
        'source_dir': config.sourceDir,
        'output_prefix': config.outputPrefix,
        'remove_comments': config.removeComments,
      },
      'summary': {
        'file_count': chunk.length,
        'total_size': chunk.fold<int>(0, (sum, f) => sum + f.contentSize),
      },
      'files': chunk.map((FileInfo file) {
        return {
          'path': file.relativePath,
          'size': file.sizeBytes,
          'content_size': file.contentSize,
          'last_modified': file.lastModified.toIso8601String(),
          'content': file.content,
        };
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Create a markdown anchor from a file path
  String _makeAnchor(String path) {
    return path
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  /// Get total output size for a list of output files
  static Future<int> getTotalOutputSize(List<String> outputPaths) async {
    int total = 0;
    for (final path in outputPaths) {
      final file = File(path);
      if (await file.exists()) {
        total += await file.length();
      }
    }
    return total;
  }
}
