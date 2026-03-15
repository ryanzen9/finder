class HelpRequest {
  final String id;
  final String author;
  final String title;
  final String location;
  final String timeText;
  final String description;
  final String? imagePath;
  final List<String> imagePaths;

  const HelpRequest({
    required this.id,
    required this.author,
    required this.title,
    required this.location,
    required this.timeText,
    this.description = '',
    this.imagePath,
    this.imagePaths = const [],
  });
}
