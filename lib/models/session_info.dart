class SessionInfo {
  SessionInfo({
    required this.filename,
    required this.title,
    this.createdAt,
    this.modifiedAt,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      if (value is int && value > 0) {
        return DateTime.fromMillisecondsSinceEpoch(
          value > 1000000000000 ? value : value * 1000,
        );
      }
      return null;
    }

    final fn = json['filename']?.toString() ?? json['id']?.toString() ?? '';
    final rawTitle = json['title']?.toString();
    return SessionInfo(
      filename: fn,
      title: (rawTitle != null && rawTitle.isNotEmpty)
          ? rawTitle
          : (fn.isNotEmpty ? fn : 'Untitled Chat'),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      modifiedAt: parseDate(json['modifiedAt'] ?? json['modified_at']),
    );
  }

  final String filename;
  final String title;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
}
