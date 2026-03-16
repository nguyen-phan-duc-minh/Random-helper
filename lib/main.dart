import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/theme.dart';
import 'data/repositories/spin_repository_impl.dart';
import 'presentation/providers/spin_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/pages/main_dashboard.dart';

void main() {
  runApp(const RandomHelperApp());
}

class RandomHelperApp extends StatelessWidget {
  const RandomHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SpinRepositoryImpl>(
          create: (_) => SpinRepositoryImpl(),
        ),
        ChangeNotifierProxyProvider<SpinRepositoryImpl, SpinProvider>(
          create: (context) => SpinProvider(
            context.read<SpinRepositoryImpl>(),
          ),
          update: (context, repository, previous) =>
              previous ?? SpinProvider(repository),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Random Helper',
            theme: appTheme,
            darkTheme: appDarkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const MainDashboard(),
          );
        },
      ),
    );
  }
}
