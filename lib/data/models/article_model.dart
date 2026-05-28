class Article {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final String category;
  final String? author;
  final String? publishedAt;
  final List<String>? tags;

  const Article({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.category,
    this.author,
    this.publishedAt,
    this.tags,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      author: json['author'],
      publishedAt: json['publishedAt'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'category': category,
        'author': author,
        'publishedAt': publishedAt,
        'tags': tags,
      };
}
