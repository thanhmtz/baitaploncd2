class BloodPressure {
  final int systolic;
  final int diastolic;
  final int pulse;
  final DateTime timestamp;
  final String? notes;

  BloodPressure({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'hour': timestamp.hour,
      'minute': timestamp.minute,
      'notes': notes ?? '',
    };
  }

  factory BloodPressure.fromJson(Map<String, dynamic> json, {DateTime? date}) {
    return BloodPressure(
      systolic: (json['systolic'] as num?)?.toInt() ?? 0,
      diastolic: (json['diastolic'] as num?)?.toInt() ?? 0,
      pulse: (json['pulse'] as num?)?.toInt() ?? 0,
      timestamp: date != null
          ? DateTime(
              date.year,
              date.month,
              date.day,
              (json['hour'] as num?)?.toInt() ?? 0,
              (json['minute'] as num?)?.toInt() ?? 0,
            )
          : DateTime.now(),
      notes: json['notes'] as String?,
    );
  }

  String get category {
    if (systolic > 180 || diastolic > 120) return 'Crisis';
    if (systolic >= 140 || diastolic >= 90) return 'High Stage 2';
    if (systolic >= 130 || diastolic >= 80) return 'High Stage 1';
    if (systolic >= 120) return 'Elevated';
    if (diastolic >= 80) return 'High Stage 1';
    return 'Normal';
  }
}
