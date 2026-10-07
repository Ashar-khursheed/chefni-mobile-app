import '../network/api_client.dart';

class ReelItem {
  const ReelItem({
    required this.id,
    required this.title,
    required this.caption,
    required this.chef,
    required this.videoUrl,
    required this.durationSec,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    this.recipeId,
  });

  final String id;
  final String title;
  final String caption;
  final String chef;
  final String videoUrl;
  final int durationSec;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final String? recipeId;

  factory ReelItem.fromJson(Map<String, dynamic> json) => ReelItem(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        chef: json['chef'] as String? ?? '',
        videoUrl: json['video_url'] as String? ?? '',
        durationSec: (json['duration_sec'] as num?)?.toInt() ?? 0,
        likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
        commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
        isLiked: json['is_liked'] as bool? ?? false,
        recipeId: json['recipe_id']?.toString(),
      );

  ReelItem copyWith({bool? isLiked, int? likesCount}) => ReelItem(
        id: id,
        title: title,
        caption: caption,
        chef: chef,
        videoUrl: videoUrl,
        durationSec: durationSec,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount,
        isLiked: isLiked ?? this.isLiked,
        recipeId: recipeId,
      );
}

class ReelRepository {
  ReelRepository(this._api);

  final ApiClient _api;

  Future<List<ReelItem>> fetchOfficialReels() async {
    final json = await _api.get('/reels/official');
    return (json['data'] as List)
        .map((e) => ReelItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns the server's authoritative like state and count.
  Future<({bool isLiked, int likesCount})> toggleLike(String id) async {
    final json = await _api.post('/reels/official/$id/like');
    return (
      isLiked: json['is_liked'] as bool? ?? false,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
    );
  }
}
