import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capture_studio/controllers/capture_controller.dart';
import 'package:capture_studio/core/app_theme.dart';
import 'package:capture_studio/widgets/camera_grid_card.dart';
import 'package:capture_studio/widgets/image_empty_state.dart';
import 'package:capture_studio/views/home_view.dart';
import 'unit_test.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('CameraGridCard displays required labels and handles tap', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 200,
                child: CameraGridCard(
                  onTap: () => tapped = true,
                  isCapturing: false,
                ),
              ),
            ),
          ),
        ),
      );

      // Verify labels and camera icon
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Tap to capture'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

      // Tap card
      await tester.tap(find.text('Take Photo'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('CameraGridCard shows loading progress when capturing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 200,
                child: CameraGridCard(onTap: () {}, isCapturing: true),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Opening...'), findsOneWidget);
      expect(find.text('Please wait'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ImageEmptyState renders title and action button', (
      tester,
    ) async {
      bool buttonTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ImageEmptyState(
              onCapturePressed: () => buttonTapped = true,
              isCapturing: false,
            ),
          ),
        ),
      );

      expect(find.text('No moments captured yet'), findsOneWidget);
      expect(find.text('Take First Photo'), findsOneWidget);

      await tester.tap(find.text('Take First Photo'));
      await tester.pump();
      expect(buttonTapped, isTrue);
    });

    testWidgets(
      'HomeView renders Capture Studio title and permanent camera card',
      (tester) async {
        final mockCamera = MockCameraService();
        final mockStorage = MockStorageService();
        final controller = CaptureController(
          cameraService: mockCamera,
          storageService: mockStorage,
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<CaptureController>.value(
                value: controller,
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const HomeView(),
            ),
          ),
        );

        // Settle frame and async post frame callbacks
        await tester.pumpAndSettle();

        // Verify Title and Subtitle
        expect(find.text('Capture Studio'), findsOneWidget);
        expect(
          find.text('Capture moments, keep them organized.'),
          findsOneWidget,
        );

        // Verify gallery count badge
        expect(find.text('0 photos'), findsOneWidget);

        // Verify permanent Camera Card is present
        expect(find.text('Take Photo'), findsWidgets);
      },
    );
  });
}
