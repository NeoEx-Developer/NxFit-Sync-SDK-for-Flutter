import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nxfit_sdk/core.dart';
import 'package:workmanager/workmanager.dart';

import 'MyApp.dart';
import 'NxfitSyncDispatcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(nxfitSyncDispatcher);

  setBasicLogger();

  Logger.root.level = Level.ALL;

  runApp(const MyApp());
}
