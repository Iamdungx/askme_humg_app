import 'package:get_it/get_it.dart';
import 'package:askme_humg/app/services/api_client.dart';

final GetIt di = GetIt.instance;

Future<void> setupDependencies() async {
  // Network
  di.registerLazySingleton<ApiClient>(() => ApiClient());
}
