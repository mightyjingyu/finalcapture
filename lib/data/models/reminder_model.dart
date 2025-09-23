import 'package:equatable/equatable.dart';

class ReminderModel extends Equatable {
  final String id;
  final String photoId;
  final String userId;
  final String title;
  final String? description;
  final DateTime reminderDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;
  final bool isNotified;
  final ReminderType type;
  final Map<String, dynamic> metadata;

  const ReminderModel({
    required this.id,
    required this.photoId,
    required this.userId,
    required this.title,
    this.description,
    required this.reminderDate,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
    this.isNotified = false,
    this.type = ReminderType.general,
    this.metadata = const {},
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      photoId: json['photoId'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      reminderDate: DateTime.parse(json['reminderDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isNotified: json['isNotified'] as bool? ?? false,
      type: ReminderType.values.firstWhere(
        (e) => e.toString() == 'ReminderType.${json['type']}',
        orElse: () => ReminderType.general,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photoId': photoId,
      'userId': userId,
      'title': title,
      'description': description,
      'reminderDate': reminderDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isCompleted': isCompleted,
      'isNotified': isNotified,
      'type': type.name,
      'metadata': metadata,
    };
  }

  ReminderModel copyWith({
    String? id,
    String? photoId,
    String? userId,
    String? title,
    String? description,
    DateTime? reminderDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    bool? isNotified,
    ReminderType? type,
    Map<String, dynamic>? metadata,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      photoId: photoId ?? this.photoId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderDate: reminderDate ?? this.reminderDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      isNotified: isNotified ?? this.isNotified,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        photoId,
        userId,
        title,
        description,
        reminderDate,
        createdAt,
        updatedAt,
        isCompleted,
        isNotified,
        type,
        metadata,
      ];
}

enum ReminderType {
  general,
  schedule,
  deadline,
  appointment,
  payment,
  event,
}

extension ReminderTypeExtension on ReminderType {
  String get displayName {
    switch (this) {
      case ReminderType.general:
        return '일반';
      case ReminderType.schedule:
        return '일정';
      case ReminderType.deadline:
        return '마감일';
      case ReminderType.appointment:
        return '약속';
      case ReminderType.payment:
        return '결제';
      case ReminderType.event:
        return '이벤트';
    }
  }

  String get icon {
    switch (this) {
      case ReminderType.general:
        return '🔔';
      case ReminderType.schedule:
        return '📅';
      case ReminderType.deadline:
        return '⏰';
      case ReminderType.appointment:
        return '🤝';
      case ReminderType.payment:
        return '💳';
      case ReminderType.event:
        return '🎉';
    }
  }
}
