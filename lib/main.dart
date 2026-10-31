import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'controllers/text_extractor_controller.dart';
import 'core/app_theme.dart';
import 'views/text_extractor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for a clean edge-to-edge theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TextExtractorController>(
          create: (_) => TextExtractorController(),
        ),
      ],
      child: const TextExtractorApp(),
    ),
  );
}

class TextExtractorApp extends StatelessWidget {
  const TextExtractorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Text Extractor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const TextExtractorScreen(),
    );
  }
}
