class CoursePaginationModel {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const CoursePaginationModel({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory CoursePaginationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CoursePaginationModel(
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
      totalPages: json['totalPages'],
    );
  }
}