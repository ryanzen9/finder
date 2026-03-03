class ManualTag {
  final String id;
  final String name;

  const ManualTag({required this.id, required this.name});
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
}
