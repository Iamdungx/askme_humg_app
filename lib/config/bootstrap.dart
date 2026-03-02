import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:askme_humg/config/env_reader.dart';
import 'package:askme_humg/firebase_options.dart';

class AppBootstrap {
  const AppBootstrap._();

  static late SharedPreferences sharedPreferences;

  static Future<void> init() async {
    // Silently ignore missing .env (CI / machines without local file)
    await dotenv.load(fileName: '.env').catchError((_) {});

    // Register timeago locale messages for all supported languages.
    // Must run before any timeago.format() call.
    timeago.setLocaleMessages('vi', timeago.ViMessages());
    timeago.setLocaleMessages('ja', timeago.JaMessages());

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

    // google_sign_in v7: serverClientId (Web Client ID) is required on Android.
    // Get from: Firebase Console → Project Settings → General → Web app → Client ID
    await GoogleSignIn.instance.initialize(
      serverClientId: EnvReader.googleServerClientId.isNotEmpty
          ? EnvReader.googleServerClientId
          : null,
    );

    sharedPreferences = await SharedPreferences.getInstance();
  }
}
