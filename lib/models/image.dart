/// Metadata for uploaded images
///
/// Contains information about images stored in Firebase Storage
class ImageMetadata {
  final String name;
  final int size;
  final String contentType;
  final DateTime timeCreated;
  final DateTime updated;
  final String? downloadURL;

  ImageMetadata({
    required this.name,
    required this.size,
    required this.contentType,
    required this.timeCreated,
    required this.updated,
    this.downloadURL,
  });

  factory ImageMetadata.fromJson(Map<String, dynamic> json) {
    return ImageMetadata(
      name: json['name'] as String,
      size: json['size'] as int,
      contentType: json['contentType'] as String,
      timeCreated: DateTime.parse(json['timeCreated'] as String),
      updated: DateTime.parse(json['updated'] as String),
      downloadURL: json['downloadURL'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'contentType': contentType,
      'timeCreated': timeCreated.toIso8601String(),
      'updated': updated.toIso8601String(),
      if (downloadURL != null) 'downloadURL': downloadURL,
    };
  }

  /// Format file size in human-readable format
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
