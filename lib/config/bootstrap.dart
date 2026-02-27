import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:askme_humg/config/env_reader.dart';
import 'package:askme_humg/firebase_options.dart';

class AppBootstrap {
  const AppBootstrap._();

  static late SharedPreferences sharedPreferences;

  static Future<void> init() async {
    // Silently ignore missing .env (CI / machines without local file)
    await dotenv.load(fileName: '.env').catchError((_) {});

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      providerAndroid: EnvReader.isRelease
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
      providerApple: EnvReader.isRelease
          ? const AppleDeviceCheckProvider()
          : const AppleDebugProvider(),
    );

    // google_sign_in v7: must call initialize() once before any usage
    await GoogleSignIn.instance.initialize();

    sharedPreferences = await SharedPreferences.getInstance();
  }
}
