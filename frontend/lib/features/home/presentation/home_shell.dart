import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:permission_handler/permission_handler.dart';

import '../../../shared/widgets/animated_bottom_nav.dart';

import '../../profile_allergies/presentation/profile_screen.dart';

import '../../scan_barcode/presentation/product_result_sheet.dart';

import '../../scan_barcode/presentation/scan_controller.dart';

import '../../scan_dish/presentation/picture_tab.dart';
import '../../profile_allergies/presentation/allergy_controller.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  MobileScannerController? _scanner;

  bool _permissionChecked = false;

  bool _permissionGranted = false;

  bool _permissionPermanentlyDenied = false;

  static const _scanTabIndex = 1;

  static const _productFormats = {
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
  };

  int _selectedIndex = _scanTabIndex;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (!mounted) return;

    setState(() {
      _permissionChecked = true;

      _permissionGranted = status.isGranted;

      _permissionPermanentlyDenied = status.isPermanentlyDenied;

      if (_permissionGranted) {
        _scanner = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          formats: const [
            BarcodeFormat.ean13,
            BarcodeFormat.ean8,
            BarcodeFormat.upcA,
            BarcodeFormat.upcE,
            BarcodeFormat.qrCode,
            BarcodeFormat.code128,
            BarcodeFormat.code39,
          ],
        );
      }
    });
  }

  @override
  void dispose() {
    _scanner?.dispose();

    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_selectedIndex != _scanTabIndex || _isProcessing) return;

    Barcode? detected;

    for (final b in capture.barcodes) {
      if (b.rawValue != null && b.rawValue!.isNotEmpty) {
        detected = b;

        break;
      }
    }
    if (detected == null) return;

    setState(() => _isProcessing = true);

    final value = detected.rawValue!;

    try {
      if (_productFormats.contains(detected.format)) {
        final allergies = ref.read(allergyControllerProvider).value ?? [];
        if (allergies.isEmpty) {
          _showSnack(
            'Aucune allergie enregistrée. Allez dans votre profil pour en ajouter.',
          );
          return;
        }
        await ref.read(scanControllerProvider.notifier).scan(value, allergies);

        if (!mounted) return;

        final state = ref.read(scanControllerProvider);

        final product = state.value;

        if (state.hasError) {
          _showSnack(state.error.toString());
        } else if (product != null) {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => ProductResultSheet(product: product),
          );
        }
      } else {
        await _showRawSheet(value);
      }
    } finally {
      if (mounted) {
        ref.read(scanControllerProvider.notifier).reset();

        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showRawSheet(String value) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_2),
                  const SizedBox(width: 10),
                  Text(
                    'Code détecté',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(value),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_permissionGranted) {
      return _PermissionDeniedScreen(
        permanent: _permissionPermanentlyDenied,
        onRetry: _permissionPermanentlyDenied ? null : _requestCameraPermission,
      );
    }

    final isLoading = ref.watch(scanControllerProvider).isLoading;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          if (_selectedIndex == _scanTabIndex)
            Positioned.fill(
              child: MobileScanner(
                controller: _scanner!,
                onDetect: _onDetect,
                fit: BoxFit.cover,
                errorBuilder: (context, error) => _CameraError(error: error),
              ),
            ),
          Positioned.fill(child: _buildOverlay()),
          if (isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x88000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AnimatedBottomNav(
        currentIndex: _selectedIndex,
        onTap: (i) {
          if (i != _scanTabIndex) {
            _scanner?.stop();
          }
          setState(() => _selectedIndex = i);
        },
      ),
    );
  }

  Widget _buildOverlay() {
    switch (_selectedIndex) {
      case 0:
        return const PictureTab();

      case 2:
        return _ProfilePanel(
          color: Theme.of(context).colorScheme.surface,
          child: const ProfileScreen(),
        );

      case _scanTabIndex:
      default:
        return const _ScanReticle();
    }
  }
}

class _PermissionDeniedScreen extends StatelessWidget {
  const _PermissionDeniedScreen({
    required this.permanent,
    required this.onRetry,
  });

  final bool permanent;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 20),
              Text(
                'Accès à la caméra requis',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                permanent
                    ? 'La permission a été refusée définitivement. '
                          'Activez-la manuellement dans les paramètres de l\'application.'
                    : 'L\'accès à la caméra est nécessaire pour scanner '
                          'les codes-barres et photographier les plats.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (permanent)
                FilledButton.icon(
                  onPressed: openAppSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Ouvrir les paramètres'),
                )
              else
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Autoriser la caméra'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanReticle extends StatelessWidget {
  const _ScanReticle();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Visez un code-barres ou un QR code',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.child, required this.color});

  final Widget child;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: color.withValues(alpha: 0.94), child: child);
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              Text(
                'Caméra indisponible.\n${error.errorDetails?.message ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
