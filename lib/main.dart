import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'controllers/capture_controller.dart';
import 'core/app_theme.dart';
import 'services/camera_service.dart';
import 'services/local_image_storage_service.dart';
import 'views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for a premium edge-to-edge white theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final storageService = LocalImageStorageService();
  final cameraService = CameraService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CaptureController>(
          create: (_) => CaptureController(
            cameraService: cameraService,
            storageService: storageService,
          ),
        ),
      ],
      child: const CaptureStudioApp(),
    ),
  );
}

class CaptureStudioApp extends StatelessWidget {
  const CaptureStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capture Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeView(),
    );
  }
}
