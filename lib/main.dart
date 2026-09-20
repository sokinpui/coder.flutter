import 'dart:ui';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'state/coder_state.dart';
import 'views/responsive_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.initializeFonts();
  runApp(const MyApp());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final CoderState _coderState;

  @override
  void initState() {
    super.initState();
    _coderState = CoderState();
  }

  @override
  void dispose() {
    _coderState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _coderState,
      builder: (context, _) {
        return MaterialApp(
          title: 'coder',
          debugShowCheckedModeBanner: false,
          scrollBehavior: const AppScrollBehavior(),
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: _coderState.themeMode,
          home: ResponsiveHome(state: _coderState),
        );
      },
    );
  }
}
