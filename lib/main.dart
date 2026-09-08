import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'state/coder_state.dart';
import 'views/responsive_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
          title: 'Coder',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: _coderState.themeMode,
          home: ResponsiveHome(state: _coderState),
        );
      },
    );
  }
}
