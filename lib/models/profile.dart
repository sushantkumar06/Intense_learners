class ProfileData {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? bio;
  final String? location;
  final String? dateOfBirth;
  final String? avatar;
  final String? qualification;
  final String? experience;
  final String? subjects;
  final String? specialization;
  final String? teachingStyle;
  final String? website;
  final String? linkedin;
  final String? twitter;
  final String? instagram;
  final String role;

  ProfileData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.bio,
    this.location,
    this.dateOfBirth,
    this.avatar,
    this.qualification,
    this.experience,
    this.subjects,
    this.specialization,
    this.teachingStyle,
    this.website,
    this.linkedin,
    this.twitter,
    this.instagram,
    required this.role,
  });

  factory ProfileData.fromJson(Map<dynamic, dynamic> raw) {
    String? parseString(dynamic val) {
      if (val == null) return null;
      if (val is List) {
        return val
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .join(", ");
      }
      return val.toString();
    }

    return ProfileData(
      id: parseString(raw['id'] ?? raw['_id']) ?? '',
      name: parseString(raw['name']) ?? '',
      email: parseString(raw['email']) ?? '',
      phone: parseString(raw['phone']) ?? '',
      bio: parseString(raw['bio']),
      location: parseString(raw['location']),
      dateOfBirth: parseString(raw['dateOfBirth']),
      avatar: parseString(raw['avatar']),
      qualification: parseString(raw['qualification']),
      experience: parseString(raw['experience']),
      subjects: parseString(raw['subjects']),
      specialization: parseString(raw['specialization']),
      teachingStyle: parseString(raw['teachingStyle']),
      website: parseString(raw['website']),
      linkedin: parseString(raw['linkedin']),
      twitter: parseString(raw['twitter']),
      instagram: parseString(raw['instagram']),
      role: parseString(raw['role']) ?? 'STUDENT',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'bio': bio,
      'location': location,
      'dateOfBirth': dateOfBirth,
      'avatar': avatar,
      'qualification': qualification,
      'experience': experience,
      'subjects': subjects,
      'specialization': specialization,
      'teachingStyle': teachingStyle,
      'website': website,
      'linkedin': linkedin,
      'twitter': twitter,
      'instagram': instagram,
      'role': role,
    };
  }
}
