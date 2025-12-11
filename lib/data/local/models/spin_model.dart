// lib/data/local/models/spin_model.dart
import '../../../domain/entities/spin.dart';
import '../../../core/constants.dart';

class SpinModel extends Spin {
  const SpinModel({
    int? id,
    required String name,
    String? themeColor,
    required int createdAt,
    int? spinDuration,
  }) : super(
          id: id,
          name: name,
          themeColor: themeColor,
          createdAt: createdAt,
          spinDuration: spinDuration,
        );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'theme_color': themeColor,
        'created_at': createdAt,
        'spin_duration': spinDuration ?? AppConstants.defaultSpinDuration,
      };

  factory SpinModel.fromMap(Map<String, dynamic> map) => SpinModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        themeColor: map['theme_color'] as String?,
        createdAt: map['created_at'] as int,
        spinDuration: map['spin_duration'] as int?,
      );
}
