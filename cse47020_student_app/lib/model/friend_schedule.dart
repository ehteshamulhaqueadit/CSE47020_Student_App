class FriendSchedule {
  final String name;
  final String id;
  final List<Course> courses;

  FriendSchedule({
    required this.name,
    required this.id,
    required this.courses,
  });

  factory FriendSchedule.fromJson(Map<String, dynamic> json) {
    return FriendSchedule(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
      courses: (json['courses'] as List<dynamic>? ?? [])
          .map((e) => Course.fromJson(e))
          .toList(),
    );
  }
}

class Course {
  final String courseCode;
  final List<CourseSchedule> schedule;

  Course({required this.courseCode, required this.schedule});

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseCode: json['courseCode'] ?? '',
      schedule: (json['schedule'] as List<dynamic>? ?? [])
          .map((e) => CourseSchedule.fromJson(e))
          .toList(),
    );
  }
}

class CourseSchedule {
  final String day;
  final String startTime;
  final String endTime;

  CourseSchedule({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory CourseSchedule.fromJson(Map<String, dynamic> json) {
    return CourseSchedule(
      day: json['day'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
    );
  }
}

