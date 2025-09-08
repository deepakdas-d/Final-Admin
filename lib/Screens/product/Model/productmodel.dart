import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id; // The document ID from Firestore
  final String name;
  final String productId;
  final String materials;
  final String description;
  final double price;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.productId,
    required this.materials,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  // Factory constructor to create a Product instance from a Firestore document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? 'No Name',
      productId: data['id'] ?? 'No ID',
      materials: data['materials'] ?? 'No Materials',
      description: data['description'] ?? 'No Description',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  // Method to convert a Product instance to a map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': productId,
      'materials': materials,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      // Assuming stock is always initialized to 0
      // Note: We don't include the 'id' field here because it's the document's ID
    };
  }
}
