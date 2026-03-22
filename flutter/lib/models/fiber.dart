class Fiber {
  final int id;
  final String text;
  final int tension;
  final String tone;
  final String? thought;
  final String? source;
  final DateTime caughtAt;
  final List<FiberReply>? replies;
  final List<FiberLink>? links;

  Fiber({
    required this.id,
    required this.text,
    required this.tension,
    required this.tone,
    this.thought,
    this.source,
    required this.caughtAt,
    this.replies,
    this.links,
  });

  factory Fiber.fromJson(Map<String, dynamic> json) {
    return Fiber(
      id: json['id'] as int,
      text: json['text'] as String,
      tension: json['tension'] as int? ?? 3,
      tone: json['tone'] as String? ?? 'hold',
      thought: json['thought'] as String?,
      source: json['source'] as String?,
      caughtAt: DateTime.parse(json['caught_at'] as String),
      replies: (json['replies'] as List<dynamic>?)
          ?.map((r) => FiberReply.fromJson(r as Map<String, dynamic>))
          .toList(),
      links: (json['links'] as List<dynamic>?)
          ?.map((l) => FiberLink.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }

  /// UI 감도 (1~100)
  int get sensitivity => tension * 20;
}

class FiberReply {
  final int id;
  final int fiberId;
  final String text;
  final DateTime createdAt;

  FiberReply({
    required this.id,
    required this.fiberId,
    required this.text,
    required this.createdAt,
  });

  factory FiberReply.fromJson(Map<String, dynamic> json) {
    return FiberReply(
      id: json['id'] as int,
      fiberId: json['fiber_id'] as int,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class FiberLink {
  final int id;
  final String? why;
  final List<Fiber>? members;

  FiberLink({
    required this.id,
    this.why,
    this.members,
  });

  factory FiberLink.fromJson(Map<String, dynamic> json) {
    return FiberLink(
      id: json['id'] as int,
      why: json['why'] as String?,
      members: (json['members'] as List<dynamic>?)
          ?.map((m) => Fiber.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
