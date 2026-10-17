import 'package:freezed_annotation/freezed_annotation.dart';

part 'roster_entry_v3.freezed.dart';
part 'roster_entry_v3.g.dart';

@freezed
abstract class RosterEntryV3 with _$RosterEntryV3 {
  const factory RosterEntryV3({
    required String playerId,
    required String teamId,
    required String userId,
    required String position,
    required int jerseyNumber,
    required DateTime joinedAt,
    DateTime? leftAt,
    Map<String, dynamic>? metadata,
  }) = _RosterEntryV3;

  factory RosterEntryV3.fromJson(Map<String, dynamic> json) => _$RosterEntryV3FromJson(json);
}

