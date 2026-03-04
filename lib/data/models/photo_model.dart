class PhotoModel {
  final int? id;
  final String title;
  final String imagePath;
  final int createdAt;

  const PhotoModel({
    this.id,
    required this.title,
    required this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'image_path': imagePath,
      'created_at': createdAt,
    };
  }

  factory PhotoModel.fromMap(Map<String, dynamic> map) {
    return PhotoModel(
      id: map['id'] as int?,
      title: (map['title'] ?? '').toString(),
      imagePath: (map['image_path'] ?? '').toString(),
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
    );
  }

  PhotoModel copyWith({
    int? id,
    String? title,
    String? imagePath,
    int? createdAt,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
