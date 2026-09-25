import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';
import 'core/errors/error_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorHandler.installGlobalHandlers();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final dependencies = await AppDependencies.create();
  runApp(SmartClassApp(dependencies: dependencies));
}
