import 'package:flutter/material.dart';

import 'app/app.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await AppController.create();
  runApp(YaseerApp(controller: controller));
}
