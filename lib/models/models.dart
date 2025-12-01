class User {
  final String username;
  final String? image; // Base64 string

  User({required this.username, this.image});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(username: json['username'], image: json['image']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.username == username;
  }

  @override
  int get hashCode => username.hashCode;
}

class Log {
  final String username;
  final int year;
  final int month;
  final List<String> logs;

  Log({
    required this.username,
    required this.year,
    required this.month,
    required this.logs,
  });

  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      username: json['username'],
      year: json['year'],
      month: json['month'],
      logs: List<String>.from(json['logs']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Log &&
        other.username == username &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode => Object.hash(username, year, month);
}
