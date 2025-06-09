
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync1/http_override.dart';
import './app.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized(); 
  await dotenv.load(fileName: ".env");
  // HttpOverrides.global = MyHttpOverrides();

  runApp(
  ProviderScope(
    observers: [
      // TalkerRiverpodObserver(),
    ],
    child: App(),
  )
 );
}

