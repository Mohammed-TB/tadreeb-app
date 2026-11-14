enum FavoriteTargetType {
  course,
  institute,
}

class FavoriteModel {
  final String id;
  final String targetId;
  final FavoriteTargetType targetType;

  FavoriteModel({
    required this.id,
    required this.targetId,
    required this.targetType,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: (json['_id'] ?? json['id']).toString(),
      targetId: json['targetId'].toString(),
      targetType: FavoriteTargetType.values.firstWhere(
        (e) => e.name == json['targetType']?.toString(),
        orElse: () => FavoriteTargetType.course,
      ),
    );
  }
}