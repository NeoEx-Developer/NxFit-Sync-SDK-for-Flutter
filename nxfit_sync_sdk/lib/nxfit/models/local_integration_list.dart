import 'package:json_annotation/json_annotation.dart';
import 'package:nxfit_sdk/models.dart';

part 'local_integration_list.g.dart';

/// LocalIntegrationList
///
/// A list of local integrations.
@JsonSerializable()
class LocalIntegrationList {
  /// A list of local integrations.
  final List<LocalIntegration>? integrations;

  /// LocalIntegrationList
  ///
  /// A list of local integrations.
  const LocalIntegrationList({this.integrations});

  factory LocalIntegrationList.fromJson(json) => _$LocalIntegrationListFromJson(json);
  Map<String, dynamic> toJson() => _$LocalIntegrationListToJson(this);
}