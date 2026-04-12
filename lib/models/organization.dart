class Organization {
  final String id;
  final String name;
  final List<String> usuarios;

  Organization({
    required this.id,
    required this.name,
    required this.usuarios,
  });

  // Esto es un constructor que permite crear el json
  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Sin nombre',

      usuarios: (json['usuarios'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
