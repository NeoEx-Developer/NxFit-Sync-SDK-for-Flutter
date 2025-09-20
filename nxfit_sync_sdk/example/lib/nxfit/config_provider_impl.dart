import 'package:nxfit_sdk/core.dart';
import 'package:rxdart/rxdart.dart';

class ConfigProviderImpl implements ConfigurationProvider {
  @override
  String get baseUrl => "https://api.dev.nxfit.io/";

  @override
  int get connectTimeoutSeconds => 30;

  @override
  HttpLoggerLevel get httpLoggerLevel => HttpLoggerLevel.none;
}