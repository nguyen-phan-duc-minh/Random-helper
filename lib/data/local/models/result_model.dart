// lib/data/local/models/result_model.dart
class ResultModel {
  final int id;
  final int spinId;
  final int itemId;
  final int timestamp;

  const ResultModel({
    required this.id,
    required this.spinId,
    required this.itemId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'spin_id': spinId,
        'item_id': itemId,
        'timestamp': timestamp,
      };

  factory ResultModel.fromMap(Map<String, dynamic> map) => ResultModel(
        id: map['id'] as int,
        spinId: map['spin_id'] as int,
        itemId: map['item_id'] as int,
        timestamp: map['timestamp'] as int,
      );
}

