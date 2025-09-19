import 'package:json_annotation/json_annotation.dart';
import 'package:nxfit_sdk/models.dart';

part 'local_integration_list.g.dart';

@JsonSerializable()
class LocalIntegrationList {
  final List<LocalIntegration>? integrations;
  const LocalIntegrationList({this.integrations});
  factory LocalIntegrationList.fromJson(json) => _$LocalIntegrationListFromJson(json);
  Map<String, dynamic> toJson() => _$LocalIntegrationListToJson(this);
}