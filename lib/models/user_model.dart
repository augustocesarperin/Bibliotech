class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  bool isAdmin() {
    return role == 'admin';
  }
} 