class Product {
  final String name, upc;
  final String? imageUrl, description, servingQuantity, servingSize;
  final Map<String, dynamic> nutrients;

  Product(
      {required this.upc,
      required this.name,
      required this.nutrients,
      this.description,
      this.imageUrl,
      this.servingQuantity,
      this.servingSize});

  factory Product.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as int?;
    if (status != 1) {
      return Product(
        upc: json['code']?.toString() ?? '',
        name: '',
        nutrients: {},
      );
    }

    final product = json['product'] as Map<String, dynamic>? ?? {};
    return Product(
      upc: json['code'].toString(),
      name: product['product_name'] ??
          product['generic_name'] ??
          '',
      description: product['generic_name'] ?? '',
      nutrients: product['nutriments'] as Map<String, dynamic>? ?? {},
      imageUrl: product['image_url']?.toString() ??
          'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg',
      servingQuantity: json['serving_quantity']?.toString(),
      servingSize: json['serving_size']?.toString(),
    );
  }
}
