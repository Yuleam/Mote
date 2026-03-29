import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config.dart';
import '../models/fiber.dart';
import '../services/api_service.dart';
import '../widgets/fiber_card.dart';
import 'focus_screen.dart';

class EncounterTab extends StatefulWidget {
  const EncounterTab({super.key});

  @override
  State<EncounterTab> createState() => _EncounterTabState();
}

class _EncounterTabState extends State<EncounterTab> {
  Fiber? _fiber;
  bool _loading = true;
  bool _empty = false;

  @override
  void initState() {
    super.initState();
    _loadEncounter();
  }

  Future<void> _loadEncounter() async {
    setState(() => _loading = true);
    final fiber = await ApiService().getEncounter();
    setState(() {
      _fiber = fiber;
      _empty = fiber == null;
      _loading = false;
    });
    if (fiber != null) {
      ApiService().recordEncounter(fiber.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Text(
                  'Mote',
                  style: GoogleFonts.gowunBatang(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // 본문
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : _empty
                    ? _buildEmpty()
                    : _buildEncounter(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '아직 조각이 없어요',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 조각을 캐치해보세요',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncounter() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),

          // 만남 안내
          Text(
            '다시 만난 조각',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          // 조각 카드
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FocusScreen(fiberId: _fiber!.id),
                ),
              );
            },
            child: FiberCard(fiber: _fiber!),
          ),

          const SizedBox(height: 32),

          // 다시 만나기 버튼
          Center(
            child: TextButton(
              onPressed: _loadEncounter,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.border),
                ),
              ),
              child: const Text('다시 만나기', style: TextStyle(fontSize: 13)),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
