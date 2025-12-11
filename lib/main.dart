import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'data/repositories/spin_repository_impl.dart';
import 'presentation/providers/spin_provider.dart';
import 'presentation/pages/home_page.dart';

void main() {
  runApp(const LuckyHubApp());
}

class LuckyHubApp extends StatelessWidget {
  const LuckyHubApp({super.key});

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
      ],
      child: MaterialApp(
        title: 'LuckyHub',
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        home: const HomePage(),
      ),
    );
  }
}
