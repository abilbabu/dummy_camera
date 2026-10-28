import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// The dedicated first card in the image gallery grid.
/// Always remains fixed at position 0, inviting users to take photos.
class CameraGridCard extends StatefulWidget {
  final VoidCallback onTap;
  final bool isCapturing;

  const CameraGridCard({
    super.key,
    required this.onTap,
    this.isCapturing = false,
  });

  @override
  State<CameraGridCard> createState() => _CameraGridCardState();
}

class _CameraGridCardState extends State<CameraGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Take Photo',
      hint: 'Opens camera to capture a new photo',
      child: Material(
        color: Colors.transparent,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.cameraCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? AppColors.primary
                    : AppColors.cameraCardBorder,
                width: _isHovered ? 1.5 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: _isHovered ? 0.08 : 0.04,
                  ),
                  blurRadius: _isHovered ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.isCapturing ? null : widget.onTap,
              splashColor: AppColors.cameraIconBg.withValues(alpha: 0.6),
              highlightColor: AppColors.cameraCardBorder.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 10.0,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Camera icon container or loading indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.cameraIconBg,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: widget.isCapturing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.cameraIcon,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 28,
                                  color: AppColors.cameraIcon,
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Primary label
                      Text(
                        widget.isCapturing ? 'Opening...' : 'Take Photo',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),
                      // Subtitle guidance
                      Text(
                        widget.isCapturing ? 'Please wait' : 'Tap to capture',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
