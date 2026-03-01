class PairedDevice {
  final String fingerprint;
  final String alias;
  final String? deviceModel;
  final String deviceType;
  final DateTime pairedAt;
  final bool alwaysAllowTerminal;

  const PairedDevice({
    required this.fingerprint,
    required this.alias,
    this.deviceModel,
    required this.deviceType,
    required this.pairedAt,
    this.alwaysAllowTerminal = false,
  });

  factory PairedDevice.fromJson(Map<String, dynamic> json) {
    return PairedDevice(
      fingerprint: json['fingerprint'] as String,
      alias: json['alias'] as String,
      deviceModel: json['deviceModel'] as String?,
      deviceType: json['deviceType'] as String,
      pairedAt: DateTime.parse(json['pairedAt'] as String),
      alwaysAllowTerminal: json['alwaysAllowTerminal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fingerprint': fingerprint,
      'alias': alias,
      'deviceModel': deviceModel,
      'deviceType': deviceType,
      'pairedAt': pairedAt.toIso8601String(),
      'alwaysAllowTerminal': alwaysAllowTerminal,
    };
  }

  PairedDevice copyWith({
    String? fingerprint,
    String? alias,
    String? deviceModel,
    String? deviceType,
    DateTime? pairedAt,
    bool? alwaysAllowTerminal,
  }) {
    return PairedDevice(
      fingerprint: fingerprint ?? this.fingerprint,
      alias: alias ?? this.alias,
      deviceModel: deviceModel ?? this.deviceModel,
      deviceType: deviceType ?? this.deviceType,
      pairedAt: pairedAt ?? this.pairedAt,
      alwaysAllowTerminal: alwaysAllowTerminal ?? this.alwaysAllowTerminal,
    );
  }
}
