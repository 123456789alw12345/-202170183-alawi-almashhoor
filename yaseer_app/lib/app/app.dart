import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/app_shell.dart';
import '../features/mode_selection_screen.dart';
import '../state/app_controller.dart';
import 'theme.dart';

class YaseerApp extends StatelessWidget {
  const YaseerApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'يسير للمبيعات والحسابات',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: YaseerTheme.light(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.isLoading) {
            return const _LoadingScreen();
          }
          if (controller.loadError != null) {
            return _LoadErrorScreen(
              error: controller.loadError!,
              onRetry: controller.initialize,
            );
          }
          if (controller.mode == null) {
            return ModeSelectionScreen(onSelect: controller.selectMode);
          }
          return YaseerShell(controller: controller);
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 18),
            Text('نرتّب حساباتك…'),
          ],
        ),
      ),
    );
  }
}

class _LoadErrorScreen extends StatelessWidget {
  const _LoadErrorScreen({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 52, color: Color(0xFFB42318)),
                const SizedBox(height: 18),
                Text('تعذر فتح البيانات',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'بياناتك لم تُحذف. حاول مرة أخرى.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => onRetry(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
