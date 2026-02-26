import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:askme_humg/config/env_reader.dart';
import 'package:askme_humg/firebase_options.dart';

class AppBootstrap {
  const AppBootstrap._();

  static late SharedPreferences sharedPreferences;

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      dotenv.testLoad(mergeWith: {});
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      androidProvider: EnvReader.isRelease
          ? AndroidProvider.playIntegrity
          : AndroidProvider.debug,
      appleProvider: EnvReader.isRelease
          ? AppleProvider.deviceCheck
          : AppleProvider.debug,
    );

    sharedPreferences = await SharedPreferences.getInstance();
  }
}
