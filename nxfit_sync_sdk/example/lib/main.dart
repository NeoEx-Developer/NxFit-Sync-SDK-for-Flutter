import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';

import 'MyApp.dart';
import 'NxfitSyncDispatcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(nxfitSyncDispatcher);

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
  });

  runApp(const MyApp());
}
