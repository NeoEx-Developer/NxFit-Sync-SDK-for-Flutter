import 'package:nxfit_sdk/core.dart';

class ConfigProviderImpl implements ConfigurationProvider {
  @override
  String get baseUrl => "https://api.dev.nxfit.io/";

  @override
  HttpLoggerLevel get httpLoggerLevel => HttpLoggerLevel.headers;

  @override
  LogLevel get minLogLevel => LogLevel.debug;

  @override
  int get connectTimeoutSeconds => 30;
}
