import '../network/api_client.dart';

/// Where a video sits in the server-side pipeline.
enum VideoStatus { queued, compressing, transcribing, extracting, ready, failed }

extension VideoStatusX on VideoStatus {
  static VideoStatus fromApi(String? value) {
    switch (value) {
      case 'compressing':
        return VideoStatus.compressing;
      case 'transcribing':
        return VideoStatus.transcribing;
      case 'extracting':
        return VideoStatus.extracting;
      case 'ready':
        return VideoStatus.ready;
      case 'failed':
        return VideoStatus.failed;
      case 'queued':
      default:
        return VideoStatus.queued;
    }
  }

  /// Shown under the progress bar while the pipeline runs.
  String get label {
    switch (this) {
      case VideoStatus.queued:
        return 'Waiting to start…';
      case VideoStatus.compressing:
        return 'Compressing into a 1-minute reel…';
      case VideoStatus.transcribing:
        return 'Listening to your video…';
      case VideoStatus.extracting:
        return 'Building your recipe card…';
      case VideoStatus.ready:
        return 'Ready';
      case VideoStatus.failed:
        return 'Failed';
    }
  }

  bool get isSettled => this == VideoStatus.ready || this == VideoStatus.failed;
}

class UserVideo {
  const UserVideo({
    required this.id,
    required this.title,
    required this.status,
    required this.progress,
    required this.isPrivate,
    this.failureReason,
    this.videoUrl,
    this.thumbnailUrl,
    this.originalSizeBytes,
    this.reelSizeBytes,
    this.compressionPercent,
    this.reelDurationSec,
    this.resolution,
    this.recipeCardId,
    this.createdAt,
  });

  final int id;
  final String title;
  final VideoStatus status;
  final int progress;
  final bool isPrivate;

  /// Set on failure, and also on success when the reel came out but the recipe
  /// did not — so it is a note, not necessarily an error.
  final String? failureReason;

  final String? videoUrl;
  final String? thumbnailUrl;
  final int? originalSizeBytes;
  final int? reelSizeBytes;
  final double? compressionPercent;
  final double? reelDurationSec;
  final String? resolution;
  final int? recipeCardId;
  final DateTime? createdAt;

  factory UserVideo.fromJson(Map<String, dynamic> json) => UserVideo(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        status: VideoStatusX.fromApi(json['status'] as String?),
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        isPrivate: json['is_private'] as bool? ?? true,
        failureReason: json['failure_reason'] as String?,
        videoUrl: json['video_url'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
        originalSizeBytes: (json['original_size_bytes'] as num?)?.toInt(),
        reelSizeBytes: (json['reel_size_bytes'] as num?)?.toInt(),
        compressionPercent: (json['compression_percent'] as num?)?.toDouble(),
        reelDurationSec: (json['reel_duration_sec'] as num?)?.toDouble(),
        resolution: json['resolution'] as String?,
        recipeCardId: (json['recipe_card_id'] as num?)?.toInt(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  bool get isSettled => status.isSettled;
  bool get hasRecipeCard => recipeCardId != null;

  /// "48.0 MB → 4.8 MB", once both sizes are known.
  String? get sizeSummary {
    if (originalSizeBytes == null || reelSizeBytes == null) return null;
    return '${_mb(originalSizeBytes!)} → ${_mb(reelSizeBytes!)}';
  }

  String? get durationLabel {
    if (reelDurationSec == null) return null;
    final total = reelDurationSec!.round();
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }

  static String _mb(int bytes) => '${(bytes / 1048576).toStringAsFixed(1)} MB';
}

class StudioRepository {
  StudioRepository(this._api);

  final ApiClient _api;

  /// Uploads the video and returns the queued record. Processing continues on
  /// the server — poll [videoStatus] until the record settles.
  ///
  /// Bytes rather than a File: the web build has no filesystem, and the picker
  /// returns bytes there.
  Future<UserVideo> uploadVideo({
    required Stream<List<int>> byteStream,
    required int totalBytes,
    required String filename,
    required String title,
    bool isPrivate = true,
    void Function(double progress)? onProgress,
  }) async {
    final json = await _api.uploadFile(
      '/studio/upload-video',
      field: 'video',
      byteStream: byteStream,
      totalBytes: totalBytes,
      filename: filename,
      fields: {'title': title, 'is_private': isPrivate ? '1' : '0'},
      onProgress: onProgress,
    );

    return UserVideo.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<UserVideo> videoStatus(int id) async {
    final json = await _api.get('/studio/videos/$id/status');
    return UserVideo.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<UserVideo>> fetchMyVideos() async {
    final json = await _api.get('/studio/videos');
    return (json['data'] as List)
        .map((e) => UserVideo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteVideo(int id) => _api.delete('/studio/videos/$id');
}
