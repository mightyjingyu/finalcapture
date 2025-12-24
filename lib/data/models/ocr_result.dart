class OCRResult {
  final String text;
  final String category;
  final double confidence;
  final List<String> tags;
  final String reasoning;

  OCRResult({
    required this.text,
    required this.category,
    required this.confidence,
    required this.tags,
    required this.reasoning,
  });
}
