class DirectoryUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatar;
  final String? phone;
  final String? bio;
  final String? location;
  final String? dateOfBirth;
  final String? qualification;
  final String? experience;
  final String? subjects;
  final String? specialization;
  final String? teachingStyle;
  final String? website;
  final String? linkedin;
  final String? twitter;
  final String? instagram;
  final bool isActive;
  final String createdAt;

  DirectoryUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    this.phone,
    this.bio,
    this.location,
    this.dateOfBirth,
    this.qualification,
    this.experience,
    this.subjects,
    this.specialization,
    this.teachingStyle,
    this.website,
    this.linkedin,
    this.twitter,
    this.instagram,
    required this.isActive,
    required this.createdAt,
  });

  factory DirectoryUser.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    return DirectoryUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'STUDENT',
      avatar: json['avatar']?.toString(),
      phone: json['phone']?.toString(),
      bio: json['bio']?.toString(),
      location: json['location']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      qualification: json['qualification']?.toString(),
      experience: json['experience']?.toString(),
      subjects: json['subjects']?.toString(),
      specialization: json['specialization']?.toString(),
      teachingStyle: json['teachingStyle']?.toString(),
      website: json['website']?.toString(),
      linkedin: json['linkedin']?.toString(),
      twitter: json['twitter']?.toString(),
      instagram: json['instagram']?.toString(),
      isActive: json['isActive'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar': avatar,
      'phone': phone,
      'bio': bio,
      'location': location,
      'dateOfBirth': dateOfBirth,
      'qualification': qualification,
      'experience': experience,
      'subjects': subjects,
      'specialization': specialization,
      'teachingStyle': teachingStyle,
      'website': website,
      'linkedin': linkedin,
      'twitter': twitter,
      'instagram': instagram,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}
