import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/cache_service.dart';
import '../../services/upload_service.dart';
import '../../models/profile.dart';
import '../../theme/app_theme.dart';
import '../../components/safe_back_scope.dart';
import '../../components/ui/ui.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  String _tab = "basic";
  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;

  String? _avatarUrl;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _dobController;
  late final TextEditingController _qualificationController;
  late final TextEditingController _experienceController;
  late final TextEditingController _subjectsController;
  late final TextEditingController _specializationController;
  late final TextEditingController _teachingStyleController;
  late final TextEditingController _websiteController;
  late final TextEditingController _linkedinController;
  late final TextEditingController _twitterController;
  late final TextEditingController _instagramController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _dobController = TextEditingController();
    _qualificationController = TextEditingController();
    _experienceController = TextEditingController();
    _subjectsController = TextEditingController();
    _specializationController = TextEditingController();
    _teachingStyleController = TextEditingController();
    _websiteController = TextEditingController();
    _linkedinController = TextEditingController();
    _twitterController = TextEditingController();
    _instagramController = TextEditingController();

    _initFromAuthAndCache();
    _fetchProfile();
  }

  void _initFromAuthAndCache() {
    final authUser = ref.read(authProvider).user;
    if (authUser != null) {
      if (authUser['email'] != null) {
        _emailController.text = authUser['email'].toString();
      }
      _applyUserData(ProfileData.fromJson(authUser));
      _loading = false;
    }

    final cached = CacheService.getSync("cached_user_profile_v1");
    if (cached is Map) {
      _applyUserData(ProfileData.fromJson(cached));
      _loading = false;
    }
  }

  void _applyUserData(ProfileData p) {
    if (!mounted) return;
    setState(() {
      if (p.avatar != null && p.avatar!.isNotEmpty) {
        _avatarUrl = p.avatar;
      }
      if (p.name.isNotEmpty) _nameController.text = p.name;
      if (p.email.isNotEmpty) _emailController.text = p.email;
      if (p.phone.isNotEmpty) _phoneController.text = p.phone;
      if (p.bio != null) _bioController.text = p.bio!;
      if (p.location != null) _locationController.text = p.location!;
      if (p.dateOfBirth != null) {
        final dob = p.dateOfBirth!;
        _dobController.text = dob.length >= 10 ? dob.substring(0, 10) : dob;
      }
      if (p.qualification != null) _qualificationController.text = p.qualification!;
      if (p.experience != null) _experienceController.text = p.experience!;
      if (p.subjects != null) _subjectsController.text = p.subjects!;
      if (p.specialization != null) _specializationController.text = p.specialization!;
      if (p.teachingStyle != null) _teachingStyleController.text = p.teachingStyle!;
      if (p.website != null) _websiteController.text = p.website!;
      if (p.linkedin != null) _linkedinController.text = p.linkedin!;
      if (p.twitter != null) _twitterController.text = p.twitter!;
      if (p.instagram != null) _instagramController.text = p.instagram!;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _dobController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _subjectsController.dispose();
    _specializationController.dispose();
    _teachingStyleController.dispose();
    _websiteController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    DateTime initial = DateTime.tryParse(_dobController.text) ?? DateTime(2002, 1, 1);
    if (initial.isAfter(DateTime.now())) initial = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.indigo,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final y = picked.year.toString();
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() {
        _dobController.text = "$y-$m-$d";
      });
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/api/user/profile');
      final data = response.data;
      if (data is Map) {
        final userRaw = data['user'] is Map ? data['user'] : data;
        final p = ProfileData.fromJson(userRaw as Map);

        if (mounted) {
          _applyUserData(p);
          CacheService.set("cached_user_profile_v1", p.toJson());
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted && _nameController.text.isEmpty && _phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load your profile")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handlePickAvatar() async {
    setState(() => _uploadingAvatar = true);
    try {
      final uploadService = ref.read(uploadServiceProvider);
      final result = await uploadService.pickAndUploadImage();
      if (result != null && mounted) {
        setState(() => _avatarUrl = result.url);
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final updateData = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "bio": _bioController.text.trim(),
        "location": _locationController.text.trim(),
        "dateOfBirth": _dobController.text.trim().isEmpty ? null : _dobController.text.trim(),
        "qualification": _qualificationController.text.trim(),
        "experience": _experienceController.text.trim(),
        "subjects": _subjectsController.text.trim(),
        "specialization": _specializationController.text.trim(),
        "teachingStyle": _teachingStyleController.text.trim(),
        "website": _websiteController.text.trim(),
        "linkedin": _linkedinController.text.trim(),
        "twitter": _twitterController.text.trim(),
        "instagram": _instagramController.text.trim(),
        "avatar": _avatarUrl,
      };

      await dio.put('/api/user/profile', data: updateData);

      // Update cached profile
      CacheService.set("cached_user_profile_v1", updateData);

      final cachedStudentProfile = CacheService.getSync("cached_student_profile_v1");
      if (cachedStudentProfile is Map) {
        final map = Map<String, dynamic>.from(cachedStudentProfile);
        final innerProf = map['profile'] is Map ? Map<String, dynamic>.from(map['profile'] as Map) : <String, dynamic>{};
        innerProf.addAll(updateData);
        map['profile'] = innerProf;
        CacheService.set("cached_student_profile_v1", map);
      }

      // Update authProvider user in SharedPreferences and refresh
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        final updatedUser = Map<String, dynamic>.from(currentUser);
        updatedUser['name'] = _nameController.text.trim();
        updatedUser['phone'] = _phoneController.text.trim();
        if (_avatarUrl != null) updatedUser['avatar'] = _avatarUrl;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(updatedUser));
        ref.read(authProvider.notifier).hydrate();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your profile has been updated")),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          final isTeacher = ref.read(authProvider).user?['role'] == 'TEACHER';
          context.go(isTeacher ? '/teacher' : '/student/profile');
        }
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile")),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: AppTypography.body.copyWith(
              fontSize: 14,
              color: readOnly && onTap == null ? AppColors.inkMuted : AppColors.ink,
            ),
            cursorColor: const Color(0xFF2EE6C5),
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly && onTap == null ? const Color(0x0DFFFFFF) : const Color(0x14FFFFFF),
              hintText: placeholder,
              hintStyle: AppTypography.body.copyWith(color: AppColors.inkFaint, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: suffixIcon,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0x26FFFFFF), width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0x992EE6C5), width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0x14FFFFFF), width: 1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isTeacher = user?['role'] == 'TEACHER';

    final tabs = [
      {"id": "basic", "label": "Basic Info"},
      if (isTeacher) {"id": "professional", "label": "Professional"},
      {"id": "social", "label": "Social"},
    ];

    final displayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (user?['name']?.toString() ?? '?');

    final fallback = isTeacher ? '/teacher' : '/student/profile';

    return SafeBackScope(
      fallbackLocation: fallback,
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    AnimatedPressable(
                      pressScale: 0.9,
                      onPress: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(fallback);
                        }
                      },
                      child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: AppRadius.smBorder,
                      ),
                      alignment: Alignment.center,
                      child: Icon(LucideIcons.arrowLeft, size: 18, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Edit Profile",
                    style: AppTypography.h3.copyWith(fontSize: 16, color: AppColors.ink),
                  ),
                ],
              ),
            ),

            if (_loading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.indigo),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Avatar Section
                    Center(
                      child: Column(
                        children: [
                          AnimatedPressable(
                            pressScale: 0.95,
                            onPress: _handlePickAvatar,
                            disabled: _uploadingAvatar,
                            child: Stack(
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: AppColors.indigo,
                                    shape: BoxShape.circle,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  alignment: Alignment.center,
                                  child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                      ? Image.network(
                                          _avatarUrl!,
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Text(
                                            displayName[0].toUpperCase(),
                                            style: AppTypography.stat.copyWith(
                                              color: Colors.white,
                                              fontSize: 34,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          displayName[0].toUpperCase(),
                                          style: AppTypography.stat.copyWith(
                                            color: Colors.white,
                                            fontSize: 34,
                                          ),
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.indigo,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.paper, width: 2.5),
                                    ),
                                    alignment: Alignment.center,
                                    child: _uploadingAvatar
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(LucideIcons.camera, color: Colors.white, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            "Tap to change photo",
                            style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      padding: const EdgeInsets.all(3),
                      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: Row(
                        children: tabs.map((t) {
                          final active = _tab == t["id"];
                          return Expanded(
                            child: AnimatedPressable(
                              pressScale: 0.97,
                              onPress: () => setState(() => _tab = t["id"]!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: active ? AppColors.indigo : Colors.transparent,
                                  borderRadius: AppRadius.smBorder,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  t["label"]!,
                                  style: AppTypography.label.copyWith(
                                    fontSize: 12,
                                    color: active ? Colors.white : AppColors.inkMuted,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    if (_tab == "basic") ...[
                      _buildField(
                        label: "Full Name",
                        controller: _nameController,
                      ),
                      _buildField(
                        label: "Email",
                        controller: _emailController,
                        readOnly: true,
                      ),
                      _buildField(
                        label: "Phone",
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildField(
                        label: "Location",
                        controller: _locationController,
                        placeholder: "City, State",
                      ),
                      _buildField(
                        label: "Date of Birth",
                        controller: _dobController,
                        placeholder: "YYYY-MM-DD",
                        readOnly: true,
                        onTap: _selectDateOfBirth,
                        suffixIcon: Icon(LucideIcons.calendar, size: 18, color: AppColors.inkMuted),
                      ),
                      _buildField(
                        label: "Bio",
                        controller: _bioController,
                        maxLines: 4,
                        placeholder: "Tell us a bit about yourself…",
                      ),
                    ],

                    if (_tab == "professional") ...[
                      _buildField(
                        label: "Qualification",
                        controller: _qualificationController,
                        placeholder: "e.g., M.Sc Physics",
                      ),
                      _buildField(
                        label: "Experience",
                        controller: _experienceController,
                        placeholder: "e.g., 5 years",
                      ),
                      _buildField(
                        label: "Subjects",
                        controller: _subjectsController,
                        placeholder: "e.g., Physics, Mathematics",
                      ),
                      _buildField(
                        label: "Specialization",
                        controller: _specializationController,
                      ),
                      _buildField(
                        label: "Teaching Style",
                        controller: _teachingStyleController,
                        maxLines: 3,
                      ),
                    ],

                    if (_tab == "social") ...[
                      _buildField(
                        label: "Website",
                        controller: _websiteController,
                        placeholder: "https://…",
                        textCapitalization: TextCapitalization.none,
                        keyboardType: TextInputType.url,
                      ),
                      _buildField(
                        label: "LinkedIn",
                        controller: _linkedinController,
                        placeholder: "https://linkedin.com/in/…",
                        textCapitalization: TextCapitalization.none,
                        keyboardType: TextInputType.url,
                      ),
                      _buildField(
                        label: "Twitter / X",
                        controller: _twitterController,
                        placeholder: "https://x.com/…",
                        textCapitalization: TextCapitalization.none,
                        keyboardType: TextInputType.url,
                      ),
                      _buildField(
                        label: "Instagram",
                        controller: _instagramController,
                        placeholder: "https://instagram.com/…",
                        textCapitalization: TextCapitalization.none,
                        keyboardType: TextInputType.url,
                      ),

                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        margin: const EdgeInsets.only(top: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.indigoTint,
                          borderRadius: AppRadius.mdBorder,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(LucideIcons.info, size: 16, color: AppColors.indigo),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isTeacher
                                    ? "Adding your social profiles helps students and parents learn more about your teaching approach and credentials."
                                    : "Connect your social profiles to showcase your personality and interests!",
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.indigo,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: "Cancel",
                      variant: AppButtonVariant.ghost,
                      disabled: _saving,
                      customPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      onPress: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(fallback);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: AppButton(
                      label: "Save Changes",
                      variant: AppButtonVariant.primary,
                      icon: LucideIcons.save,
                      loading: _saving,
                      disabled: _saving,
                      customPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      onPress: _handleSave,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
