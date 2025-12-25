/// Job Status
///
/// Represents the processing status of a DocuPipe document processing job
class JobStatus {
  final String jobId;
  final String status; // 'pending', 'processing', 'completed', 'failed'
  final String? documentId;
  final double? progress; // 0.0 to 1.0
  final String? error;
  final DateTime? createdAt;
  final DateTime? completedAt;

  JobStatus({
    required this.jobId,
    required this.status,
    this.documentId,
    this.progress,
    this.error,
    this.createdAt,
    this.completedAt,
  });

  factory JobStatus.fromJson(Map<String, dynamic> json) {
    return JobStatus(
      jobId: json['jobId'] as String,
      status: json['status'] as String,
      documentId: json['documentId'] as String?,
      progress: json['progress'] != null ? (json['progress'] as num).toDouble() : null,
      error: json['error'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'status': status,
      if (documentId != null) 'documentId': documentId,
      if (progress != null) 'progress': progress,
      if (error != null) 'error': error,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing' || status == 'pending';
}

/// Document Result
///
/// Represents a processed document with extracted text and metadata
class DocumentResult {
  final String documentId;
  final String originalFilename;
  final String mimeType;
  final int fileSize;
  final String dataset;
  final String extractedText;
  final Map<String, dynamic>? metadata;
  final List<String>? pages;
  final DateTime? uploadedAt;
  final DateTime? processedAt;

  DocumentResult({
    required this.documentId,
    required this.originalFilename,
    required this.mimeType,
    required this.fileSize,
    required this.dataset,
    required this.extractedText,
    this.metadata,
    this.pages,
    this.uploadedAt,
    this.processedAt,
  });

  factory DocumentResult.fromJson(Map<String, dynamic> json) {
    return DocumentResult(
      documentId: json['documentId'] as String,
      originalFilename: json['originalFilename'] as String,
      mimeType: json['mimeType'] as String,
      fileSize: json['fileSize'] as int,
      dataset: json['dataset'] as String,
      extractedText: json['extractedText'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      pages: json['pages'] != null ? List<String>.from(json['pages'] as List) : null,
      uploadedAt: json['uploadedAt'] != null ? DateTime.parse(json['uploadedAt'] as String) : null,
      processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'originalFilename': originalFilename,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'dataset': dataset,
      'extractedText': extractedText,
      if (metadata != null) 'metadata': metadata,
      if (pages != null) 'pages': pages,
      if (uploadedAt != null) 'uploadedAt': uploadedAt!.toIso8601String(),
      if (processedAt != null) 'processedAt': processedAt!.toIso8601String(),
    };
  }
}

/// Standardization Result
///
/// Represents standardized/normalized data from DocuPipe AI processing
class StandardizationResult {
  final String standardizationId;
  final String documentId;
  final String type; // 'menu', 'address', 'contact', etc.
  final Map<String, dynamic> standardizedData;
  final double confidence; // 0.0 to 1.0
  final DateTime? createdAt;

  StandardizationResult({
    required this.standardizationId,
    required this.documentId,
    required this.type,
    required this.standardizedData,
    required this.confidence,
    this.createdAt,
  });

  factory StandardizationResult.fromJson(Map<String, dynamic> json) {
    return StandardizationResult(
      standardizationId: json['standardizationId'] as String,
      documentId: json['documentId'] as String,
      type: json['type'] as String,
      standardizedData: json['standardizedData'] as Map<String, dynamic>,
      confidence: (json['confidence'] as num).toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'standardizationId': standardizationId,
      'documentId': documentId,
      'type': type,
      'standardizedData': standardizedData,
      'confidence': confidence,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
