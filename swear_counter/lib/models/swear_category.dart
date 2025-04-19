class SwearCategory {
  final String category;
  final int count;
  final List<String> examples;

  SwearCategory({
    required this.category,
    required this.count,
    this.examples = const [],
  });
}