import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/core/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FitnessDateApp(api: ApiClient()));
}
