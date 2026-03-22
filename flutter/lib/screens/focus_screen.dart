import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../models/fiber.dart';
import '../services/api_service.dart';

class FocusScreen extends StatefulWidget {
  final int fiberId;
  const FocusScreen({super.key, required this.fiberId});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  Fiber? _fiber;
  List<FiberLink> _links = [];
  bool _loading = true;
  final _replyController = TextEditingController();
  bool _sendingReply = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final fiber = await ApiService().getFiber(widget.fiberId);
    List<FiberLink> links = [];
    if (fiber != null) {
      links = await ApiService().getFiberLinks(fiber.id);
    }
    setState(() {
      _fiber = fiber;
      _links = links;
      _loading = false;
    });
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingReply = true);
    await ApiService().addReply(widget.fiberId, text);
    _replyController.clear();
    setState(() => _sendingReply = false);
    _load();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('이 조각을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: AppColors.toneCritic)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService().deleteFiber(widget.fiberId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _showLinkSheet() {
    final searchController = TextEditingController();
    List<Fiber> results = [];
    int? selectedId;
    final whyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('연결하기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),

                  // 검색
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: '조각 검색...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (q) async {
                      if (q.trim().isEmpty) return;
                      final r = await ApiService().searchFibers(q.trim());
                      setSheetState(() {
                        results = r.where((f) => f.id != widget.fiberId).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // 검색 결과
                  if (results.isNotEmpty)
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final f = results[i];
                          final selected = selectedId == f.id;
                          return ListTile(
                            dense: true,
                            selected: selected,
                            selectedTileColor: AppColors.accent.withValues(alpha: 0.08),
                            title: Text(
                              f.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13),
                            ),
                            leading: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.toneColor(f.tone),
                                shape: BoxShape.circle,
                              ),
                            ),
                            onTap: () => setSheetState(() => selectedId = f.id),
                          );
                        },
                      ),
                    ),

                  if (selectedId != null) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: whyController,
                      decoration: InputDecoration(
                        hintText: '왜 연결되나요?',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final why = whyController.text.trim();
                          if (why.isEmpty) return;
                          await ApiService().createLink(
                            [widget.fiberId, selectedId!],
                            why,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('연결'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textMuted),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.link, size: 20, color: AppColors.textMuted),
            onPressed: _fiber != null ? _showLinkSheet : null,
            tooltip: '연결하기',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
            onPressed: _fiber != null ? _delete : null,
            tooltip: '삭제',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _fiber == null
              ? const Center(child: Text('조각을 찾을 수 없어요'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final fiber = _fiber!;
    final color = AppColors.toneColor(fiber.tone);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // 방향성 + 감도
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppColors.toneLabel(fiber.tone),
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: (fiber.tension / 5) * 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 본문
          Text(
            fiber.text,
            style: GoogleFonts.gowunBatang(
              fontSize: 18,
              height: 1.9,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),

          // 출처
          if (fiber.source != null && fiber.source!.isNotEmpty) ...[
            Text(
              '— ${fiber.source}',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
          ],

          // 생각
          if (fiber.thought != null && fiber.thought!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                fiber.thought!,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 시간
          Text(
            DateFormat('yyyy년 M월 d일 HH:mm').format(fiber.caughtAt),
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),

          const SizedBox(height: 28),

          // 연결
          if (_links.isNotEmpty) ...[
            Text(
              '연결',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            ..._links.map((link) => _buildLink(link)),
            const SizedBox(height: 20),
          ],

          // 답글
          Text(
            '답글',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),

          if (fiber.replies != null && fiber.replies!.isNotEmpty)
            ...fiber.replies!.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.text, style: const TextStyle(fontSize: 14, height: 1.5)),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('M/d HH:mm').format(r.createdAt),
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )),

          // 답글 입력
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '답글 남기기...',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendReply(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendingReply ? null : _sendReply,
                icon: _sendingReply
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 20, color: AppColors.accent),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLink(FiberLink link) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (link.why != null && link.why!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                link.why!,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),
            ),
          if (link.members != null)
            ...link.members!
                .where((m) => m.id != widget.fiberId)
                .map((m) => GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FocusScreen(fiberId: m.id),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.toneColor(m.tone),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                m.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
        ],
      ),
    );
  }
}
