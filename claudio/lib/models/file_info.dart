/// Information about a file being processed
class FileInfo {
  /// Absolute path to the file
  final String path;

  /// Path relative to the source directory
  final String relativePath;

  /// File size in bytes
  final int sizeBytes;

  /// Last modification time
  final DateTime lastModified;

  /// File content (may have comments removed)
  final String content;

  /// Whether this file was ignored
  final bool wasIgnored;

  /// Reason for ignoring (if wasIgnored is true)
  final String? ignoreReason;

  const FileInfo({
    required this.path,
    required this.relativePath,
    required this.sizeBytes,
    required this.lastModified,
    required this.content,
    this.wasIgnored = false,
    this.ignoreReason,
  });

  /// Create a FileInfo for an ignored file
  factory FileInfo.ignored({
    required String path,
    required String relativePath,
    required String reason,
  }) {
    return FileInfo(
      path: path,
      relativePath: relativePath,
      sizeBytes: 0,
      lastModified: DateTime.now(),
      content: '',
      wasIgnored: true,
      ignoreReason: reason,
    );
  }

  /// Get content size after processing
  int get contentSize => content.length;

  @override
  String toString() {
    if (wasIgnored) {
      return 'FileInfo(ignored: $relativePath, reason: $ignoreReason)';
    }
    return 'FileInfo($relativePath, ${sizeBytes}B)';
  }
}
