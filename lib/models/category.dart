class Category {
  final int id;
  final String judul;

  Category({
    required this.id,
    required this.judul,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      judul: json['judul'],
    );
  }
}
