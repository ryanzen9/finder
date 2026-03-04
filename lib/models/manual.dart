class ManualTag {
  final String id;
  final String name;

  const ManualTag({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory ManualTag.fromJson(Map<String, dynamic> json) => ManualTag(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
      );
}

class ManualItem {
  final String id;
  final String title;
  final String brand;
  final String model;
  final String room;
  final DateTime updatedAt;
  final List<ManualTag> tags;
  final String coverGradient;
  final bool underWarranty;

  const ManualItem({
    required this.id,
    required this.title,
    required this.brand,
    required this.model,
    required this.room,
    required this.updatedAt,
    required this.tags,
    required this.coverGradient,
    required this.underWarranty,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'brand': brand,
        'model': model,
        'room': room,
        'updatedAt': updatedAt.toIso8601String(),
        'tags': tags.map((e) => e.toJson()).toList(),
        'coverGradient': coverGradient,
        'underWarranty': underWarranty,
      };

  factory ManualItem.fromJson(Map<String, dynamic> json) => ManualItem(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        brand: (json['brand'] ?? '').toString(),
        model: (json['model'] ?? '').toString(),
        room: (json['room'] ?? '').toString(),
        updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ?? DateTime.now(),
        tags: ((json['tags'] as List?) ?? const [])
            .map((e) => ManualTag.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        coverGradient: (json['coverGradient'] ?? 'purple').toString(),
        underWarranty: json['underWarranty'] == true,
      );
}
