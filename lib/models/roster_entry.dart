import 'package:freezed_annotation/freezed_annotation.dart';
part 'roster_entry.freezed.dart';
part 'roster_entry.g.dart';

@freezed
abstract class RosterEntry with _$RosterEntry {
  const factory RosterEntry({
    required String playerId,
    String? role, // eg "starter", "bench"
    int? jerseyNumber,
    DateTime? addedAt,
  }) = _RosterEntry;

  factory RosterEntry.fromJson(Map<String,dynamic> json) => _$RosterEntryFromJson(json);
}