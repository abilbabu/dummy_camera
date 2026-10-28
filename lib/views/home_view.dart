import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/capture_controller.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../models/captured_image.dart';
import '../widgets/camera_grid_card.dart';
import '../widgets/captured_image_card.dart';
import '../widgets/image_empty_state.dart';
import 'image_preview_view.dart';

/// The primary Home View for "Capture Studio".
/// Features a permanent Camera Card at index 0, followed by captured photos.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // Load persisted images from SQLite on screen initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaptureController>().initialize();
    });
  }

  void _navigateToPreview(BuildContext context, CapturedImage image) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ImagePreviewView(image: image)));
  }

  Future<void> _confirmDelete(BuildContext context, CapturedImage image) async {
    final controller = context.read<CaptureController>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text(
            'Delete Photo?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this photo? It will be removed permanently from device storage.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.photo_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        image.fileName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      image.formattedFileSize,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final success = await controller.deleteImage(image);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo deleted successfully.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                controller.errorMessage ?? 'Failed to delete photo.',
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleCapture(BuildContext context) async {
    final controller = context.read<CaptureController>();
    final success = await controller.capturePhoto();

    if (!success && controller.hasError && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage!),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Capture Studio',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Capture moments, keep them organized.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
        actions: [
          // Total saved images badge in header
          Consumer<CaptureController>(
            builder: (context, controller, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cameraCardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.cameraCardBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${controller.totalCount} ${controller.totalCount == 1 ? "photo" : "photos"}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: Consumer<CaptureController>(
          builder: (context, controller, child) {
            // Initial loading state
            if (controller.isLoading) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading your studio gallery...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            final images = controller.images;

            return LayoutBuilder(
              builder: (context, constraints) {
                final columnCount = Responsive.getColumnCount(context);
                final crossSpacing = Responsive.getCrossAxisSpacing(context);
                final mainSpacing = Responsive.getMainAxisSpacing(context);
                final aspectRatio = Responsive.getAspectRatio(context);
                final padding = Responsive.getScreenPadding(context);

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => controller.loadImages(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Gallery Section Header with quick info
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          padding.left,
                          padding.top,
                          padding.right,
                          8.0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.grid_view_rounded,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'GALLERY',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                controller.totalCount == 0
                                    ? 'Camera ready'
                                    : 'Most recent first',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Responsive Grid with Camera Card permanently at Index 0
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          padding.left,
                          4.0,
                          padding.right,
                          80.0, // bottom padding for floating action button
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columnCount,
                                crossAxisSpacing: crossSpacing,
                                mainAxisSpacing: mainSpacing,
                                childAspectRatio: aspectRatio,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              // Item 0 is ALWAYS the dedicated Camera Card
                              if (index == 0) {
                                return CameraGridCard(
                                  isCapturing: controller.isCapturing,
                                  onTap: () => _handleCapture(context),
                                );
                              }

                              // Subsequent items are the captured images in reverse chronological order
                              final imageIndex = index - 1;
                              final image = images[imageIndex];

                              return CapturedImageCard(
                                image: image,
                                onTap: () => _navigateToPreview(context, image),
                                onDelete: () => _confirmDelete(context, image),
                              );
                            },
                            // Total items = 1 (Camera Card) + number of captured photos
                            childCount: 1 + images.length,
                          ),
                        ),
                      ),

                      // Empty state message when no photos exist yet
                      if (images.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: ImageEmptyState(
                              isCapturing: controller.isCapturing,
                              onCapturePressed: () => _handleCapture(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      // Floating Camera Action Button for immediate access while scrolling
      floatingActionButton: Consumer<CaptureController>(
        builder: (context, controller, _) {
          return FloatingActionButton.extended(
            onPressed: controller.isCapturing
                ? null
                : () => _handleCapture(context),
            icon: controller.isCapturing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.camera_alt_rounded),
            label: Text(
              controller.isCapturing ? 'Opening...' : 'Take Photo',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }
}
