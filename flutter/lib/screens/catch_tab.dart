import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config.dart';
import '../models/fiber.dart';
import '../services/api_service.dart';
import '../widgets/fiber_card.dart';
import 'focus_screen.dart';

class CatchTab extends StatefulWidget {
  const CatchTab({super.key});

  @override
  State<CatchTab> createState() => _CatchTabState();
}

class _CatchTabState extends State<CatchTab> {
  final _textController = TextEditingController();
  final _sourceController = TextEditingController();
  final _thoughtController = TextEditingController();
  String _tone = 'hold';
  double _sensitivity = 50;
  bool _saving = false;
  Timer? _peripheryTimer;
  List<Fiber> _periphery = [];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _peripheryTimer?.cancel();
    final text = _textController.text.trim();
    if (text.length < 10) {
      setState(() => _periphery = []);
      return;
    }
    _peripheryTimer = Timer(const Duration(milliseconds: 800), () async {
      final results = await ApiService().getPeriphery(
        text: text,
        tone: _tone,
        source: _sourceController.text.trim(),
      );
      if (mounted) setState(() => _periphery = results);
    });
  }

  Future<void> _catch() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);
    final tension = (_sensitivity / 20).ceil().clamp(1, 5);
    final fiber = await ApiService().createFiber(
      text: text,
      tension: tension,
      tone: _tone,
      thought: _thoughtController.text.trim(),
      source: _sourceController.text.trim(),
    );
    setState(() => _saving = false);

    if (fiber != null && mounted) {
      // 입력 초기화
      _textController.clear();
      _sourceController.clear();
      _thoughtController.clear();
      setState(() {
        _tone = 'hold';
        _sensitivity = 50;
        _periphery = [];
      });
      // 포커스뷰로 이동
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FocusScreen(fiberId: fiber.id)),
      );
    }
  }

  @override
  void dispose() {
    _peripheryTimer?.cancel();
    _textController.dispose();
    _sourceController.dispose();
    _thoughtController.dispose();
    super.dispose();
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
                  '캐치',
                  style: GoogleFonts.gowunBatang(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 텍스트 입력
                  TextField(
                    controller: _textController,
                    maxLines: null,
                    minLines: 4,
                    style: GoogleFonts.gowunBatang(
                      fontSize: 16,
                      height: 1.8,
                      color: AppColors.text,
                    ),
                    decoration: InputDecoration(
                      hintText: '잡고 싶은 문장을 적어주세요',
                      hintStyle: GoogleFonts.gowunBatang(
                        fontSize: 16,
                        color: AppColors.textMuted,
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 출처
                  TextField(
                    controller: _sourceController,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    decoration: InputDecoration(
                      hintText: '출처 (선택)',
                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 방향성
                  Row(
                    children: [
                      _toneButton('positive', '공감'),
                      const SizedBox(width: 6),
                      _toneButton('critic', '비판'),
                      const SizedBox(width: 6),
                      _toneButton('hold', '보류'),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 감도
                  Row(
                    children: [
                      Text(
                        '감도',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                            activeTrackColor: AppColors.text,
                            inactiveTrackColor: AppColors.border,
                            thumbColor: AppColors.text,
                            overlayColor: AppColors.accent.withValues(alpha: 0.1),
                          ),
                          child: Slider(
                            value: _sensitivity,
                            min: 1,
                            max: 100,
                            onChanged: (v) => setState(() => _sensitivity = v),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${_sensitivity.round()}',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 생각
                  TextField(
                    controller: _thoughtController,
                    maxLines: null,
                    minLines: 2,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    decoration: InputDecoration(
                      hintText: '생각 (선택)',
                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 캐치 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _catch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('캐치', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 주변부
                  if (_periphery.isNotEmpty) ...[
                    Text(
                      '주변부',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    ..._periphery.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FocusScreen(fiberId: f.id),
                            ),
                          ),
                          child: FiberCard(fiber: f, compact: true),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toneButton(String tone, String label) {
    final active = _tone == tone;
    final color = AppColors.toneColor(tone);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tone = tone),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(
              color: active ? color : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(20),
            color: active ? color.withValues(alpha: 0.08) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? color : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
