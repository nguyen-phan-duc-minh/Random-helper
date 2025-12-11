class Item {
  final int? id;
  final int? spinId;
  final String label;
  final int weight;
  final String? color;

  const Item({
    this.id,
    this.spinId,
    required this.label,
    this.weight = 1,
    this.color,
  });

  Item copyWith({
    int? id,
    int? spinId,
    String? label,
    int? weight,
    String? color,
  }) => Item(
    id: id ?? this.id,
    spinId: spinId ?? this.spinId,
    label: label ?? this.label,
    weight: weight ?? this.weight,
    color: color ?? this.color,
  );
}
