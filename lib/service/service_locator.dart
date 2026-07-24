import 'package:get_it/get_it.dart';

import '../core/network/dio_services.dart';
import '../features/chat/cubit/chat_cubit.dart';
import '../features/chat/repos/chat_repos.dart';

final serviceLocator = GetIt.asNewInstance();

class DI {
  static Future<void> execute() async {
    // serviceLocator.registerFactory<Dio>(() => DioServices.dio);

    serviceLocator.registerFactory<DioServices>(() => DioServices());

    serviceLocator.registerFactory<ChatRepository>(
      () => ChatRepositoryImpl(serviceLocator<DioServices>()),
    );

    serviceLocator.registerFactory<ChatCubit>(
      () => ChatCubit(serviceLocator<ChatRepository>()),
    );
  }
}
