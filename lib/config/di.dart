import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:askme_humg/app/services/api_client.dart';

final GetIt di = GetIt.instance;

Future<void> setupDependencies() async {
  // Firebase
  di.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  di.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  di.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // Network
  di.registerLazySingleton<ApiClient>(() => ApiClient());
}
