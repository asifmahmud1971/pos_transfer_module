import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_transfer/features/transfer/view/home_screen.dart';
import 'core/utils/notification_service.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/transfer/cubit/transfer_cubit.dart';
import 'features/transfer/repository/transfer_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(),
        ),
        RepositoryProvider<TransferRepository>(
          create: (context) => TransferRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider<TransferCubit>(
            create: (context) => TransferCubit(
              transferRepository: context.read<TransferRepository>(),
              authCubit: context.read<AuthCubit>(),
            )..loadPersistedTransfers(),
          ),
        ],
        child: MaterialApp(
          title: 'POS Transfer Module',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}