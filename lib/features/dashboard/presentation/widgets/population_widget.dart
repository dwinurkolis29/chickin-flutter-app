import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/core/services/firebase_service.dart';

class PopulationSection extends StatefulWidget {
  final int populationRemain;

  const PopulationSection({Key? key, required this.populationRemain})
      : super(key: key);

  @override
  State<PopulationSection> createState() => _PopulationSectionState();
}

class _PopulationSectionState extends State<PopulationSection>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CageData? _cageData;
  bool _isLoading = true;
  String _errorMessage = '';

  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<int> _counterAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Initialize with default values to prevent LateInitializationError
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_animationController);

    _counterAnimation = IntTween(
      begin: 0,
      end: 0,
    ).animate(_animationController);

    // Memuat data kandang ketika halaman pertama kali dibuka
    _loadCageData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Memuat data kandang dari Firebase
  Future<void> _loadCageData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Memuat data kandang
        final cageData = await _firebaseService.getCage();
        if (mounted) {
          setState(() {
            // Memperbarui state dengan data kandang
            _cageData = cageData;
            _isLoading = false;
          });

          // Start animation after data is loaded
          _startAnimation();
        }
      } else {
        setState(() {
          // Menampilkan pesan jika pengguna belum login
          _errorMessage = 'Pengguna tidak login';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  void _startAnimation() {
    if (_cageData == null || _cageData!.capacity == 0) return;

    final targetProgress = widget.populationRemain / _cageData!.capacity;

    // Update animations with actual target values
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: targetProgress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _counterAnimation = IntTween(
      begin: 0,
      end: widget.populationRemain,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Menghitung persentase ayam yang masih hidup dari jumlah populasi
    double progress = _cageData == null || _cageData!.capacity == 0
        ? 0
        : widget.populationRemain / (_cageData?.capacity ?? 1);
    String percentage = (progress * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Populasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AnimatedBuilder(
                  animation: _counterAnimation,
                  builder: (context, child) {
                    return Text(
                      _counterAnimation.value.toString(),
                      style: TextStyle(
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    'Ekor ayam',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 100,
              height: 100,
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  final animatedPercentage =
                      (_progressAnimation.value * 100).toStringAsFixed(1);

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _progressAnimation.value,
                        strokeWidth: 10,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$animatedPercentage%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'dari 100%',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 5),
          ],
        ),
      ],
    );
  }
}
