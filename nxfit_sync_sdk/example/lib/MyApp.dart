import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'package:nxfit_sdk/core.dart';
import 'package:nxfit_sdk/models.dart';
import 'package:nxfit_sync_sdk/nxfit_sync_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';
import 'nxfit/auth_provider_impl.dart';
import 'nxfit/config_provider_impl.dart';
import 'package:app_links/app_links.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String _redirectScheme = 'com.neoex.nxfit.sync-sdk.example://';
  static final _logger = Logger('example.main');
  static final _appLinks = AppLinks();
  static final _configProvider = ConfigProviderImpl();
  static final _authProvider = AuthProviderImpl();
  final List<dynamic> _subs = [];

  List<IntegrationModel> _integrations = [];

  late NxFit _nxFitSdk;
  late NxFitManagers _nxFitManagers;
  late NxfitSyncSdk _nxfitSyncSdk;

  @override
  void initState() {
    super.initState();
    initSdkState();
  }

  Future<void> initSdkState() async {
    _nxFitSdk = NxFit.build(_configProvider, _authProvider);
    _nxfitSyncSdk = await NxfitSyncSdk.build(_configProvider, _authProvider);
    _nxFitManagers = await NxFitManagers.build(_nxFitSdk, baseRedirectUri: _redirectScheme, localSyncClient: _nxfitSyncSdk);

    _subs.add(
      _nxFitManagers.integrationsManager.connectionEvents.listen((event) async {
        _logger.info("Connection - integration: ${event.integrationIdentifier}; result: ${event.connectionCode}");
        await _nxFitManagers.integrationsManager.refreshIntegrations();
      }),
    );

    _subs.add(
      _nxFitManagers.integrationsManager.disconnectionEvents.listen((event) async {
        _logger.info("Disconnection - integration: ${event.integrationIdentifier}");
        await _nxFitManagers.integrationsManager.refreshIntegrations();
      }),
    );

    _subs.add(
      _appLinks.uriLinkStream.listen((uri) async {
        _logger.info("Deep link received: $uri");

        if (_nxFitManagers.integrationsManager.canHandleAuthorizeResponseFromUrl(uri)) {
          await _nxFitManagers.integrationsManager.handleAuthorizeResponseFromUrl(uri);
        }
      }),
    );

    _subs.add(
      _authProvider.authState.listen((authState) {
        if (authState.isAuthenticated) {
          _subs.add(
            _nxFitManagers.integrationsManager.integrations.listen((integrations) {
              setState(() {
                _integrations = integrations.toList();
              });
            }),
          );
        }
      }),
    );
  }

  Future<void> connect(IntegrationModel integration) async {
    await _nxFitManagers.integrationsManager.connect(integration.identifier, (url) async {
      launchUrl(url);
    });
  }

  Future<void> disconnect(IntegrationModel integration) async {
    await _nxFitManagers.integrationsManager.disconnect(integration.identifier);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(onPressed: () => {_authProvider.login()}, child: const Text("LOGIN")),
                    ElevatedButton(onPressed: () => {_authProvider.logout()}, child: const Text("LOGOUT")),
                  ],
                ),
                ElevatedButton(onPressed: () => {launchUrl(Uri.parse("${_redirectScheme}nxfit/integrations?integration=garmin&connection=success"))}, child: const Text("OPEN TEST DEEP LINK")),
                ElevatedButton(onPressed: () => {_nxFitManagers.integrationsManager.refreshIntegrations()}, child: const Text("REFRESH INTEGRATIONS")),
                ElevatedButton(
                  onPressed: () async {
                    await _nxfitSyncSdk.syncDailyMetrics();
                    await _nxfitSyncSdk.syncExerciseSessions();
                  },
                  child: const Text("SYNC DAILY & EXERCISES"),
                ),
                ElevatedButton(onPressed: registerBackgroundWorker, child: const Text("REGISTER BACKGROUND WORKER")),
                ElevatedButton(onPressed: registerInstantWorker, child: const Text("REGISTER INSTANT WORKER")),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32),
                  child: Column(
                    children: [
                      ..._integrations.map((i) {
                        return _Integration(i, i.isConnected ? disconnect : connect);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void registerBackgroundWorker() {
    if (Platform.isAndroid) {
      final uniqueName = "sync-all-task";

      Workmanager().registerPeriodicTask(uniqueName, "sync-all", frequency: Duration(minutes: 15), initialDelay: Duration(seconds: 0), existingWorkPolicy: ExistingWorkPolicy.replace);
      print("Worker Registered");
    }
  }
}

void registerInstantWorker() {
  if (Platform.isAndroid) {
    Workmanager().registerOneOffTask("instant-sync-task", "sync-all", initialDelay: Duration(seconds: 0), existingWorkPolicy: ExistingWorkPolicy.replace);
  }
}

class _Integration extends StatelessWidget {
  final IntegrationModel _integration;
  final Function(IntegrationModel) _action;

  const _Integration(this._integration, this._action);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Card(
        color: _integration.backgroundColour,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_integration.displayName, style: Theme.of(context).textTheme.titleMedium),
              IconButton(onPressed: () => _action(_integration), icon: Icon(_integration.actionIcon, size: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

extension on IntegrationModel {
  get backgroundColour => isConnected ? Colors.lightGreenAccent : Colors.white;
  get actionIcon => isConnected ? Icons.delete : Icons.add;
}
