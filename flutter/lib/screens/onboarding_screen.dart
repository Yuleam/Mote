import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0; // 0: 환영, 1: 프로필 질문

  final _occupationController = TextEditingController();
  final _contextController = TextEditingController();
  bool _saving = false;

  Future<void> _completeOnboarding() async {
    await AuthService().setOnboarded();
    widget.onComplete();
  }

  Future<void> _saveProfileAndComplete() async {
    setState(() => _saving = true);
    await ApiService().saveProfile(
      occupation: _occupationController.text.trim(),
      context: _contextController.text.trim(),
    );
    setState(() => _saving = false);
    await _completeOnboarding();
  }

  @override
  void dispose() {
    _occupationController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _page == 0 ? _buildWelcomePage() : _buildProfilePage(),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          Text(
            '환영해요',
            style: GoogleFonts.gowunBatang(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '읽고, 느끼고, 생각한\n조각들을 잡아두는 곳이에요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),

          _guideCard('○', '마주침', '과거의 조각이 다시 찾아와요'),
          const SizedBox(height: 12),
          _guideCard('+', '캐치', '영감의 순간을 가볍게 잡아두세요'),
          const SizedBox(height: 12),
          _guideCard('∿', '발자취', '내 조각들의 흐름을 돌아봐요'),

          const Spacer(flex: 3),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => setState(() => _page = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('다음', style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),

          Text(
            '조금만 알려주세요',
            style: GoogleFonts.gowunBatang(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '부담 없이, 건너뛰어도 괜찮아요',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 36),

          // 질문 1
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '어떤 일을 하고 계세요?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _occupationController,
            decoration: InputDecoration(
              hintText: '예: 디자이너, 학생, 연구자...',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // 질문 2
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '주로 어떤 순간에 영감을 잡으시나요?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contextController,
            decoration: InputDecoration(
              hintText: '예: 책을 읽다가, 산책 중에...',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.accent),
              ),
            ),
          ),

          const Spacer(flex: 3),

          // 저장 + 시작 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveProfileAndComplete,
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
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      '첫 번째 조각을 캐치해보세요',
                      style: TextStyle(fontSize: 15),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _completeOnboarding,
            child: Text(
              '건너뛰기',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _guideCard(String icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 22, color: AppColors.textMuted),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
