import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Trạng thái nước của cây.
/// Giữ tên Cactus... để không làm vỡ code cũ đang import/use.
enum CactusHydrationState {
  dry,
  low,
  good,
  over,
}

/// Trạng thái năng lượng của cây.
enum CactusEnergyState {
  exhausted,
  sleepy,
  normal,
  energetic,
}

/// Trạng thái căng thẳng của cây.
enum CactusStressState {
  calm,
  normal,
  tense,
  stressed,
}

/// Trạng thái duy trì thói quen/streak.
enum CactusConsistencyState {
  broken,
  weak,
  building,
  strong,
  legendary,
}

/// Mood tổng hợp để UI hiển thị chữ/icon.
enum TreeMoodState {
  wilted,
  tired,
  stressed,
  calm,
  healthy,
  joyful,
  legendary,
}

/// CactusVisualState đồng bộ với cây ảnh/animation mới.
///
/// File này vẫn giữ API cũ để các chỗ đang gọi:
///   provider.cactusVisualState
///   EvolvingCactusPet(level: ..., visualState: ...)
/// không cần sửa lại.
///
/// Các getter mới được thiết kế cho widget cây mới:
/// - glowPower, auraPower, sparklePower
/// - butterflyPower, fireflyPower, petalPower, heartPower
/// - droopPower, shakePower, fallenLeafPower, waterDropPower
/// - breathPower, floatPower, swayPower, idleSpeedMultiplier
@immutable
class CactusVisualState {
  final CactusHydrationState hydration;
  final CactusEnergyState energy;
  final CactusStressState stress;
  final CactusConsistencyState consistency;

  final bool completedToday;
  final bool lostStreakRecently;
  final int missedDays;

  const CactusVisualState({
    required this.hydration,
    required this.energy,
    required this.stress,
    required this.consistency,
    required this.completedToday,
    required this.lostStreakRecently,
    required this.missedDays,
  });

  const CactusVisualState.neutral()
      : hydration = CactusHydrationState.good,
        energy = CactusEnergyState.normal,
        stress = CactusStressState.normal,
        consistency = CactusConsistencyState.weak,
        completedToday = false,
        lostStreakRecently = false,
        missedDays = 0;

  /// Tạo trạng thái cây từ dữ liệu habit/streak.
  ///
  /// Giá trị score nên nằm trong khoảng 0.0 -> 1.0:
  /// - hydrationScore cao: cây tươi, nhiều glow nhẹ.
  /// - energyScore cao: cây nhảy/thở/sway vui hơn.
  /// - stressScore cao: cây rung, hiện dấu stress.
  factory CactusVisualState.fromHabit({
    required bool completedToday,
    required int streakDays,
    required int missedDays,
    bool lostStreakRecently = false,
    double hydrationScore = 0.75,
    double energyScore = 0.65,
    double stressScore = 0.35,
  }) {
    final safeMissedDays = math.max(0, missedDays);
    final safeStreakDays = math.max(0, streakDays);

    return CactusVisualState(
      hydration: _mapHydration(hydrationScore, safeMissedDays),
      energy: _mapEnergy(energyScore, completedToday, safeMissedDays),
      stress: _mapStress(stressScore, safeMissedDays, lostStreakRecently),
      consistency: _mapConsistency(
        streakDays: safeStreakDays,
        missedDays: safeMissedDays,
        lostStreakRecently: lostStreakRecently,
      ),
      completedToday: completedToday,
      lostStreakRecently: lostStreakRecently,
      missedDays: safeMissedDays,
    );
  }

  static double _clamp01(double value) {
    return value.clamp(0.0, 1.0).toDouble();
  }

  static CactusHydrationState _mapHydration(
    double score,
    int missedDays,
  ) {
    final value = _clamp01(score);

    if (missedDays >= 3) return CactusHydrationState.dry;
    if (value < 0.25) return CactusHydrationState.dry;
    if (value < 0.55) return CactusHydrationState.low;
    if (value > 0.93) return CactusHydrationState.over;

    return CactusHydrationState.good;
  }

  static CactusEnergyState _mapEnergy(
    double score,
    bool completedToday,
    int missedDays,
  ) {
    final value = _clamp01(score);

    if (missedDays >= 4) return CactusEnergyState.exhausted;
    if (missedDays >= 2) return CactusEnergyState.sleepy;
    if (completedToday && value >= 0.55) return CactusEnergyState.energetic;
    if (value < 0.25) return CactusEnergyState.exhausted;
    if (value < 0.48) return CactusEnergyState.sleepy;
    if (value > 0.78) return CactusEnergyState.energetic;

    return CactusEnergyState.normal;
  }

  static CactusStressState _mapStress(
    double score,
    int missedDays,
    bool lostStreakRecently,
  ) {
    final value = _clamp01(score);

    if (lostStreakRecently || missedDays >= 4) {
      return CactusStressState.stressed;
    }

    if (missedDays >= 2) return CactusStressState.tense;
    if (value < 0.25) return CactusStressState.calm;
    if (value < 0.62) return CactusStressState.normal;
    if (value < 0.82) return CactusStressState.tense;

    return CactusStressState.stressed;
  }

  static CactusConsistencyState _mapConsistency({
    required int streakDays,
    required int missedDays,
    required bool lostStreakRecently,
  }) {
    if (lostStreakRecently || missedDays >= 2) {
      return CactusConsistencyState.broken;
    }

    if (streakDays >= 30) return CactusConsistencyState.legendary;
    if (streakDays >= 14) return CactusConsistencyState.strong;
    if (streakDays >= 5) return CactusConsistencyState.building;

    return CactusConsistencyState.weak;
  }

  bool get isDry => hydration == CactusHydrationState.dry;

  bool get isLowHydration => hydration == CactusHydrationState.low;

  bool get isOverWatered => hydration == CactusHydrationState.over;

  bool get isWellHydrated =>
      hydration == CactusHydrationState.good ||
      hydration == CactusHydrationState.over;

  bool get isExhausted => energy == CactusEnergyState.exhausted;

  bool get isSleepy =>
      energy == CactusEnergyState.sleepy ||
      energy == CactusEnergyState.exhausted;

  bool get isEnergetic => energy == CactusEnergyState.energetic;

  bool get isCalm => stress == CactusStressState.calm;

  bool get isTense => stress == CactusStressState.tense;

  bool get isStressed =>
      stress == CactusStressState.tense ||
      stress == CactusStressState.stressed;

  bool get isVeryStressed => stress == CactusStressState.stressed;

  bool get hasStrongConsistency =>
      consistency == CactusConsistencyState.strong ||
      consistency == CactusConsistencyState.legendary;

  bool get isLegendary => consistency == CactusConsistencyState.legendary;

  bool get hasBrokenConsistency =>
      consistency == CactusConsistencyState.broken || lostStreakRecently;

  bool get isHealthy =>
      isWellHydrated && !isSleepy && !isStressed && !hasBrokenConsistency;

  bool get isHappy =>
      completedToday &&
      isWellHydrated &&
      !isStressed &&
      consistency.index >= CactusConsistencyState.building.index;

  TreeMoodState get mood {
    if (hasBrokenConsistency || isDry) return TreeMoodState.wilted;
    if (isExhausted || missedDays >= 3) return TreeMoodState.tired;
    if (isVeryStressed) return TreeMoodState.stressed;
    if (isLegendary && completedToday) return TreeMoodState.legendary;
    if (completedToday || isEnergetic) return TreeMoodState.joyful;
    if (isCalm) return TreeMoodState.calm;
    return TreeMoodState.healthy;
  }

  /// Nguồn sáng chính phía sau cây.
  /// Dùng cho halo/aura quanh cây.
  double get glowPower {
    double value = 0.0;

    if (hydration == CactusHydrationState.good) value += 0.22;
    if (hydration == CactusHydrationState.over) value += 0.16;

    if (energy == CactusEnergyState.energetic) value += 0.22;
    if (stress == CactusStressState.calm) value += 0.16;

    switch (consistency) {
      case CactusConsistencyState.legendary:
        value += 0.34;
        break;
      case CactusConsistencyState.strong:
        value += 0.26;
        break;
      case CactusConsistencyState.building:
        value += 0.14;
        break;
      case CactusConsistencyState.weak:
        value += 0.04;
        break;
      case CactusConsistencyState.broken:
        value -= 0.28;
        break;
    }

    if (completedToday) value += 0.24;

    if (hydration == CactusHydrationState.dry) value -= 0.30;
    if (hydration == CactusHydrationState.low) value -= 0.12;

    if (energy == CactusEnergyState.sleepy) value -= 0.12;
    if (energy == CactusEnergyState.exhausted) value -= 0.24;

    if (stress == CactusStressState.tense) value -= 0.12;
    if (stress == CactusStressState.stressed) value -= 0.24;

    if (lostStreakRecently) value -= 0.25;
    if (missedDays >= 2) value -= 0.10;
    if (missedDays >= 4) value -= 0.20;

    return _clamp01(value);
  }

  /// Aura phụ cho nền sáng mềm sau ảnh cây.
  double get auraPower {
    double value = glowPower * 0.72;

    if (completedToday) value += 0.18;
    if (isLegendary) value += 0.22;
    if (isHappy) value += 0.12;
    if (hasBrokenConsistency || isDry) value -= 0.32;

    return _clamp01(value);
  }

  /// Tia sáng lấp lánh quanh cây.
  double get sparklePower {
    double value = glowPower * 0.55;

    if (completedToday) value += 0.30;
    if (hasStrongConsistency) value += 0.16;
    if (isLegendary) value += 0.20;
    if (isStressed) value -= 0.16;
    if (hasBrokenConsistency) value -= 0.35;

    return _clamp01(value);
  }

  /// Đom đóm/bụi sáng bay quanh cây.
  double get fireflyPower {
    double value = 0.0;

    if (completedToday) value += 0.28;
    if (consistency == CactusConsistencyState.building) value += 0.16;
    if (consistency == CactusConsistencyState.strong) value += 0.32;
    if (consistency == CactusConsistencyState.legendary) value += 0.52;
    if (isCalm) value += 0.12;
    if (isDry || hasBrokenConsistency) value -= 0.50;

    return _clamp01(value);
  }

  /// Hoa trên cây/hoa dưới đất.
  /// Streak càng tốt thì hoa càng nổi.
  double get flowerBoost {
    double value;

    switch (consistency) {
      case CactusConsistencyState.legendary:
        value = 1.0;
        break;
      case CactusConsistencyState.strong:
        value = 0.74;
        break;
      case CactusConsistencyState.building:
        value = 0.42;
        break;
      case CactusConsistencyState.weak:
        value = 0.14;
        break;
      case CactusConsistencyState.broken:
        value = 0.0;
        break;
    }

    if (completedToday) value += 0.12;
    if (isDry) value -= 0.22;
    if (isStressed) value -= 0.14;
    if (hasBrokenConsistency) value = 0.0;

    return _clamp01(value);
  }

  /// Cánh hoa rơi quanh cây.
  double get petalPower {
    double value = 0.0;

    if (completedToday) value += 0.20;
    if (consistency == CactusConsistencyState.building) value += 0.14;
    if (consistency == CactusConsistencyState.strong) value += 0.34;
    if (consistency == CactusConsistencyState.legendary) value += 0.58;
    if (isHappy) value += 0.16;
    if (isDry || hasBrokenConsistency) value = 0.0;

    return _clamp01(value);
  }

  /// Tim nhỏ bay lên khi cây vui/hoàn thành hôm nay.
  double get heartPower {
    double value = 0.0;

    if (completedToday) value += 0.34;
    if (isHappy) value += 0.26;
    if (isLegendary && completedToday) value += 0.20;
    if (isStressed || isDry || hasBrokenConsistency) value -= 0.35;

    return _clamp01(value);
  }

  /// Độ tươi của ảnh/lá.
  /// Widget mới có thể dùng để chỉnh opacity/filter nếu cần.
  double get leafVitality {
    double value = 0.65;

    if (hydration == CactusHydrationState.good) value += 0.22;
    if (hydration == CactusHydrationState.over) value += 0.16;
    if (hydration == CactusHydrationState.low) value -= 0.14;
    if (hydration == CactusHydrationState.dry) value -= 0.34;

    if (isEnergetic) value += 0.10;
    if (isSleepy) value -= 0.10;
    if (isStressed) value -= 0.12;
    if (completedToday) value += 0.08;
    if (hasBrokenConsistency) value -= 0.18;

    return _clamp01(value);
  }

  /// Độ rũ của cây khi thiếu nước/mệt/bỏ lỡ nhiều ngày.
  double get droopPower {
    double value = 0.0;

    if (hydration == CactusHydrationState.low) value += 0.18;
    if (hydration == CactusHydrationState.dry) value += 0.42;

    if (energy == CactusEnergyState.sleepy) value += 0.18;
    if (energy == CactusEnergyState.exhausted) value += 0.34;

    if (missedDays >= 2) value += 0.12;
    if (missedDays >= 4) value += 0.20;

    return _clamp01(value);
  }

  /// Rung khi căng thẳng/mất streak.
  double get shakePower {
    double value = 0.0;

    if (stress == CactusStressState.tense) value += 0.35;
    if (stress == CactusStressState.stressed) value += 0.75;
    if (lostStreakRecently) value += 0.18;

    return _clamp01(value);
  }

  /// Nhịp thở của cây.
  /// Dùng để scale nhẹ theo trục Y/X cho cây ảnh.
  double get breathPower {
    double value = 0.42;

    if (isEnergetic) value += 0.24;
    if (completedToday) value += 0.16;
    if (isLegendary) value += 0.12;
    if (isSleepy) value -= 0.18;
    if (isExhausted) value -= 0.24;
    if (hasBrokenConsistency || isDry) value -= 0.20;

    return _clamp01(value);
  }

  /// Độ lơ lửng lên xuống.
  double get floatPower {
    double value = 0.28;

    if (isEnergetic) value += 0.26;
    if (completedToday) value += 0.16;
    if (isLegendary) value += 0.16;
    if (isSleepy) value -= 0.12;
    if (isExhausted) value -= 0.22;
    if (isVeryStressed) value -= 0.10;

    return _clamp01(value);
  }

  /// Độ nghiêng/sway của cây.
  double get swayPower {
    double value = 0.32;

    if (isEnergetic) value += 0.22;
    if (isCalm) value += 0.08;
    if (isSleepy) value -= 0.10;
    if (isVeryStressed) value += 0.12;
    if (hasBrokenConsistency) value -= 0.18;

    return _clamp01(value);
  }

  /// Tốc độ idle animation.
  /// 1.0 là bình thường, cao hơn là cây sống động hơn.
  double get idleSpeedMultiplier {
    double value = 1.0;

    if (isEnergetic) value += 0.22;
    if (completedToday) value += 0.14;
    if (isLegendary) value += 0.12;
    if (isSleepy) value -= 0.16;
    if (isExhausted) value -= 0.26;
    if (isVeryStressed) value += 0.18;

    return value.clamp(0.65, 1.55).toDouble();
  }

  /// Bóng dưới gốc cây.
  /// Cây khỏe thì bóng mềm/đậm hơn, cây mệt thì nhẹ hơn.
  double get shadowPower {
    double value = 0.42;

    if (isEnergetic || completedToday) value += 0.10;
    if (isLegendary) value += 0.10;
    if (isSleepy) value -= 0.06;
    if (isExhausted || isDry) value -= 0.12;

    return _clamp01(value);
  }

  /// Độ hiện bướm.
  /// Widget mới nên dùng power này để bướm bay từ Lv 15+,
  /// và tăng rõ ở Lv 70+ hoặc khi streak mạnh.
  double get butterflyPower {
    double value = 0.0;

    if (completedToday) value += 0.30;

    switch (consistency) {
      case CactusConsistencyState.legendary:
        value += 0.70;
        break;
      case CactusConsistencyState.strong:
        value += 0.45;
        break;
      case CactusConsistencyState.building:
        value += 0.20;
        break;
      case CactusConsistencyState.weak:
        value += 0.0;
        break;
      case CactusConsistencyState.broken:
        value = 0.0;
        break;
    }

    if (isDry) value -= 0.30;
    if (isStressed) value -= 0.22;
    if (hasBrokenConsistency) value = 0.0;

    return _clamp01(value);
  }

  /// Số bướm gợi ý cho widget animation mới.
  int get butterflyCount {
    final power = butterflyPower;

    if (power >= 0.82) return 4;
    if (power >= 0.58) return 3;
    if (power >= 0.30) return 2;
    if (power > 0.05) return 1;

    return 0;
  }

  /// Lá khô/lá rơi khi cây yếu hoặc mất streak.
  double get fallenLeafPower {
    double value = 0.0;

    if (hasBrokenConsistency) value += 0.55;
    if (isDry) value += 0.28;
    if (missedDays >= 2) value += 0.18;
    if (missedDays >= 4) value += 0.28;

    return _clamp01(value);
  }

  /// Lá xanh bay nhẹ khi cây bình thường/khỏe.
  double get leafSwirlPower {
    double value = 0.0;

    if (isHealthy) value += 0.18;
    if (completedToday) value += 0.20;
    if (hasStrongConsistency) value += 0.20;
    if (isLegendary) value += 0.16;
    if (isDry || hasBrokenConsistency) value = 0.0;

    return _clamp01(value);
  }

  /// Nứt/hiệu ứng xấu khi streak bị vỡ.
  double get crackPower {
    double value = 0.0;

    if (lostStreakRecently) value += 0.55;
    if (consistency == CactusConsistencyState.broken) value += 0.35;
    if (missedDays >= 3) value += 0.20;

    return _clamp01(value);
  }

  /// Giọt nước khi tưới quá nhiều.
  double get waterDropPower {
    if (hydration != CactusHydrationState.over) return 0.0;

    double value = 0.45;

    if (completedToday) value += 0.15;
    if (isCalm) value += 0.10;

    return _clamp01(value);
  }

  /// Hiệu ứng Zzz khi cây buồn ngủ/mệt.
  double get zzzPower {
    double value = 0.0;

    if (energy == CactusEnergyState.sleepy) value += 0.48;
    if (energy == CactusEnergyState.exhausted) value += 0.78;
    if (missedDays >= 3) value += 0.12;
    if (completedToday && !isExhausted) value -= 0.24;

    return _clamp01(value);
  }

  /// Dấu stress quanh cây.
  double get stressMarkPower {
    double value = 0.0;

    if (stress == CactusStressState.tense) value += 0.48;
    if (stress == CactusStressState.stressed) value += 0.82;
    if (lostStreakRecently) value += 0.16;

    return _clamp01(value);
  }

  /// Mưa/mây buồn nếu cây bị bỏ lâu hoặc khô.
  double get sadRainPower {
    double value = 0.0;

    if (isDry) value += 0.28;
    if (hasBrokenConsistency) value += 0.30;
    if (missedDays >= 3) value += 0.24;
    if (missedDays >= 5) value += 0.18;
    if (completedToday) value -= 0.24;

    return _clamp01(value);
  }

  /// Tổng mức sống động để widget mới quyết định có chạy controller hay không.
  bool get shouldAnimate {
    return completedToday ||
        isEnergetic ||
        isVeryStressed ||
        isLegendary ||
        glowPower > 0.15 ||
        butterflyPower > 0.05 ||
        fireflyPower > 0.05 ||
        petalPower > 0.05 ||
        fallenLeafPower > 0.05 ||
        waterDropPower > 0.05 ||
        zzzPower > 0.05 ||
        stressMarkPower > 0.05;
  }

  /// Dùng cho widget ảnh nếu muốn làm cây yếu/mờ nhẹ khi xấu trạng thái.
  double get treeOpacity {
    double value = 1.0;

    if (isDry) value -= 0.10;
    if (isExhausted) value -= 0.08;
    if (hasBrokenConsistency) value -= 0.08;

    return value.clamp(0.78, 1.0).toDouble();
  }

  /// Gợi ý độ sáng của ảnh cây.
  /// 1.0 là bình thường.
  double get treeBrightness {
    double value = 1.0;

    if (completedToday) value += 0.03;
    if (isLegendary) value += 0.04;
    if (isDry) value -= 0.06;
    if (isExhausted) value -= 0.04;
    if (hasBrokenConsistency) value -= 0.05;

    return value.clamp(0.88, 1.10).toDouble();
  }

  String get moodLabel {
    switch (mood) {
      case TreeMoodState.wilted:
        return 'Cây đang cần chăm sóc';
      case TreeMoodState.tired:
        return 'Cây hơi mệt';
      case TreeMoodState.stressed:
        return 'Cây đang căng thẳng';
      case TreeMoodState.calm:
        return 'Cây đang bình yên';
      case TreeMoodState.healthy:
        return 'Cây đang khỏe';
      case TreeMoodState.joyful:
        return 'Cây rất vui hôm nay';
      case TreeMoodState.legendary:
        return 'Cây huyền thoại';
    }
  }

  String get moodEmoji {
    switch (mood) {
      case TreeMoodState.wilted:
        return '🍂';
      case TreeMoodState.tired:
        return '🌙';
      case TreeMoodState.stressed:
        return '🌧️';
      case TreeMoodState.calm:
        return '🍃';
      case TreeMoodState.healthy:
        return '🌿';
      case TreeMoodState.joyful:
        return '🌸';
      case TreeMoodState.legendary:
        return '🦋';
    }
  }

  CactusVisualState copyWith({
    CactusHydrationState? hydration,
    CactusEnergyState? energy,
    CactusStressState? stress,
    CactusConsistencyState? consistency,
    bool? completedToday,
    bool? lostStreakRecently,
    int? missedDays,
  }) {
    return CactusVisualState(
      hydration: hydration ?? this.hydration,
      energy: energy ?? this.energy,
      stress: stress ?? this.stress,
      consistency: consistency ?? this.consistency,
      completedToday: completedToday ?? this.completedToday,
      lostStreakRecently: lostStreakRecently ?? this.lostStreakRecently,
      missedDays: missedDays ?? this.missedDays,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CactusVisualState &&
        other.hydration == hydration &&
        other.energy == energy &&
        other.stress == stress &&
        other.consistency == consistency &&
        other.completedToday == completedToday &&
        other.lostStreakRecently == lostStreakRecently &&
        other.missedDays == missedDays;
  }

  @override
  int get hashCode => Object.hash(
        hydration,
        energy,
        stress,
        consistency,
        completedToday,
        lostStreakRecently,
        missedDays,
      );
}
