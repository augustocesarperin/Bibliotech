import 'package:flutter/material.dart';

class Livro {
  final int id;
  final String title;
  final String author;
  final String? genre;
  final String? description;
  final String? storageSection;
  final String? imagePath;
  final String status;
  final String createdAt;
  final String updatedAt;

  Livro({
    required this.id,
    required this.title,
    required this.author,
    this.genre,
    this.description,
    this.storageSection,
    this.imagePath,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Livro.fromJson(Map<String, dynamic> json) {
    return Livro(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      genre: json['genre'],
      description: json['description'],
      storageSection: json['storage_section'],
      imagePath: json['image_path'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'genre': genre,
      'description': description,
      'storage_section': storageSection,
      'image_path': imagePath,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Métodos auxiliares
  bool isAvailable() {
    return status == 'available';
  }

  bool isSold() {
    return status == 'sold';
  }

  bool isReserved() {
    return status == 'reserved';
  }

  // Tradução de status para português
  String getStatusText() {
    switch (status) {
      case 'available':
        return 'Disponível';
      case 'sold':
        return 'Vendido';
      case 'reserved':
        return 'Reservado';
      default:
        return status;
    }
  }

  // Cor associada ao status
  static Color getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'sold':
        return Colors.red;
      case 'reserved':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 