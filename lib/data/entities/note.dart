import 'package:floor/floor.dart';

@Entity(tableName: 'notes')
class Note {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String title;
  final String content; // the description
  final int createdAt; // millisecondsSinceEpoch
  final double? latitude;
  final double? longitude;
  final String? placeName;

  const Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.placeName,
  });

  bool get hasLocation => latitude != null && longitude != null;

  /// Place name if we have it, otherwise the coordinates.
  String get locationLabel =>
      placeName ??
      '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';

  Note copyWith({String? title, String? content}) => Note(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        createdAt: createdAt,
        latitude: latitude,
        longitude: longitude,
        placeName: placeName,
      );
}

