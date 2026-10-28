import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Friendly empty state widget displayed when the local gallery has no saved photos.
class ImageEmptyState extends StatelessWidget {
  final VoidCallback onCapturePressed;
  final bool isCapturing;

  const ImageEmptyState({
    super.key,
    required this.onCapturePressed,
    this.isCapturing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Styled illustration badge using layered Flutter widgets
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.cameraCardBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cameraCardBorder,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.cameraIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.photo_library_outlined,
                      size: 34,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Friendly headline
            const Text(
              'No moments captured yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Helpful descriptive subtitle
            const Text(
              'Tap the camera card in the grid or the button below to take your first photo and start building your collection.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Action button
            ElevatedButton.icon(
              onPressed: isCapturing ? null : onCapturePressed,
              icon: isCapturing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.photo_camera_rounded, size: 20),
              label: Text(
                isCapturing ? 'Opening Camera...' : 'Take First Photo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
