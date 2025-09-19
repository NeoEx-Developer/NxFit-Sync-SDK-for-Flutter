// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_integration_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalIntegrationList _$LocalIntegrationListFromJson(
  Map<String, dynamic> json,
) => LocalIntegrationList(
  integrations: (json['integrations'] as List<dynamic>?)
      ?.map((e) => LocalIntegration.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LocalIntegrationListToJson(
  LocalIntegrationList instance,
) => <String, dynamic>{'integrations': instance.integrations};
