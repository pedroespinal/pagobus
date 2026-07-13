class Child {
  final String id;
  final String name;

  const Child({required this.id, required this.name});

  Map<String, Object?> toMap() => {'id': id, 'name': name};

  factory Child.fromMap(Map<String, Object?> map) {
    return Child(id: map['id'] as String, name: map['name'] as String);
  }
}
