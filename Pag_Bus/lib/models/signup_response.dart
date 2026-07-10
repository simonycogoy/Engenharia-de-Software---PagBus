class SignUpResponse {
  final int id;
  final String name;
  final String email;
  final String cpf;
  final String token;
  final DateTime createdAt;

  SignUpResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.cpf,
    required this.token,
    required this.createdAt,
  });

  factory SignUpResponse.fromJson(Map<String, dynamic> json) {
    return SignUpResponse(
      id: json["id"],
      name: json["name"],
      email: json["email"],
      cpf: json["cpf"],
      token: json["token"],
      createdAt: DateTime.parse(json["created_at"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "cpf": cpf,
      "token": token,
      "created_at": createdAt.toIso8601String(),
    };
  }
}
