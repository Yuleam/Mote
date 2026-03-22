import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../models/fiber.dart';
import '../services/api_service.dart';
import 'focus_screen.dart';

class TrailTab extends StatefulWidget {
  const TrailTab({super.key});

  @override
  State<TrailTab> createState() => _TrailTabState();
}

class _TrailTabState extends State<TrailTab> {
  List<Fiber> _fibers = [];
  bool _loading = true;
  bool _thisMonth = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    String? from;
    if (_thisMonth) {
      final now = DateTime.now();
      from = DateTime(now.year, now.month, 1).toIso8601String();
    }
    final fibers = await ApiService().getTrail(from: from);
    setState(() {
      _fibers = fibers;
      _loading = false;
    });
  }

  void _toggleRange() {
    setState(() => _thisMonth = !_thisMonth);
    _load();
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('M월 d일').format(dt);
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '발자취',
                  style: GoogleFonts.gowunBatang(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                  ),
                ),
                GestureDetector(
                  onTap: _toggleRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _thisMonth ? '이번 달' : '전체',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 목록
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : _fibers.isEmpty
                    ? Center(
                        child: Text(
                          '아직 조각이 없어요',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _fibers.length,
                        itemBuilder: (context, index) {
                          final fiber = _fibers[index];
                          return _buildTrailItem(fiber);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailItem(Fiber fiber) {
    final color = AppColors.toneColor(fiber.tone);
    final tensionWidth = (fiber.tension / 5) * 40;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FocusScreen(fiberId: fiber.id)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 방향성 점
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: 12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),

            // 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fiber.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // 감도 바
                      Container(
                        width: tensionWidth,
                        height: 3,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(fiber.caughtAt),
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
