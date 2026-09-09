class SessionInfo {
  SessionInfo({required this.filename, required this.title});

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      filename: json['filename'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Chat',
    );
  }

  final String filename;
  final String title;
}
