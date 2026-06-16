import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/widgets/animated_bottom_nav.dart';
import '../../profile_allergies/presentation/profile_screen.dart';
import '../../scan_barcode/presentation/product_result_sheet.dart';
import '../../scan_barcode/presentation/scan_controller.dart';
import '../../scan_dish/presentation/picture_tab.dart';
import '../../profile_allergies/presentation/allergy_controller.dart';


/// Ecran principal facon Yuka.
///
/// Hierarchie : Scaffold > Stack { MobileScanner plein ecran (fond permanent),
/// overlay selon l'onglet, overlay de chargement } + barre de navigation animee.
///
/// La camera reste montee en permanence (exigence spec). La detection de
/// codes-barres n'agit que sur l'onglet Scan, avec une garde anti-scans-multiples.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  // useAppLifecycleState (defaut true) du widget MobileScanner gere deja la
  // pause/reprise de la camera quand l'app passe en arriere-plan.
  final MobileScannerController _scanner = MobileScannerController(
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

  static const _scanTabIndex = 1;
  static const _productFormats = {
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
  };

  int _selectedIndex = _scanTabIndex; // Scan par defaut
  bool _isProcessing = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    // Ne traiter que sur l'onglet Scan + garde anti-scans-multiples.
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
          _showSnack('Aucune allergie enregistrée. Allez dans votre profil pour en ajouter.');
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
        // QR code ou autre : pas un produit -> afficher le contenu brut.
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
                  Text('Code détecté',
                      style: Theme.of(context).textTheme.titleLarge),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(scanControllerProvider).isLoading;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // 1. Camera plein ecran : fond permanent de l'app.
          Positioned.fill(
            child: MobileScanner(
              controller: _scanner,
              onDetect: _onDetect,
              fit: BoxFit.cover,
              errorBuilder: (context, error) => _CameraError(error: error),
            ),
          ),
          // 2. Overlay selon l'onglet selectionne.
          Positioned.fill(child: _buildOverlay()),
          // 3. Overlay de chargement pendant l'appel API.
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
        onTap: (i) => setState(() => _selectedIndex = i),
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

/// Reticule de visee decoratif (laisse passer les taps).
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

/// Panneau lisible pose sur le fond camera (onglets Picture / Profile).
class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color.withValues(alpha: 0.94),
      child: child,
    );
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
