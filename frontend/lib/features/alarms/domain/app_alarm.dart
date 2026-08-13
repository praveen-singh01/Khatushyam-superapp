class AppAlarm {
  const AppAlarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.enabled,
    required this.repeatDaily,
    required this.ringtoneId,
    required this.ringtoneTitle,
    this.ringtoneUrl,
    this.localAudioPath,
    this.label = '',
  });

  final int id;
  final int hour;
  final int minute;
  final bool enabled;
  final bool repeatDaily;
  final String ringtoneId;
  final String ringtoneTitle;
  final String? ringtoneUrl;
  final String? localAudioPath;
  final String label;

  String get timeLabel {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  AppAlarm copyWith({
    int? hour,
    int? minute,
    bool? enabled,
    bool? repeatDaily,
    String? ringtoneId,
    String? ringtoneTitle,
    String? ringtoneUrl,
    String? localAudioPath,
    String? label,
    bool clearLocalPath = false,
  }) {
    return AppAlarm(
      id: id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      repeatDaily: repeatDaily ?? this.repeatDaily,
      ringtoneId: ringtoneId ?? this.ringtoneId,
      ringtoneTitle: ringtoneTitle ?? this.ringtoneTitle,
      ringtoneUrl: ringtoneUrl ?? this.ringtoneUrl,
      localAudioPath:
          clearLocalPath ? null : (localAudioPath ?? this.localAudioPath),
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'enabled': enabled,
    'repeatDaily': repeatDaily,
    'ringtoneId': ringtoneId,
    'ringtoneTitle': ringtoneTitle,
    'ringtoneUrl': ringtoneUrl,
    'localAudioPath': localAudioPath,
    'label': label,
  };

  factory AppAlarm.fromJson(Map<String, dynamic> json) {
    return AppAlarm(
      id: (json['id'] as num).toInt(),
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num).toInt(),
      enabled: json['enabled'] as bool? ?? true,
      repeatDaily: json['repeatDaily'] as bool? ?? true,
      ringtoneId: json['ringtoneId'] as String? ?? '',
      ringtoneTitle: json['ringtoneTitle'] as String? ?? 'Ringtone',
      ringtoneUrl: json['ringtoneUrl'] as String?,
      localAudioPath: json['localAudioPath'] as String?,
      label: json['label'] as String? ?? '',
    );
  }
}
