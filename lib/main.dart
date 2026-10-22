import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/teacher/teacher_dashboard_screen.dart';
import 'screens/teacher/notes_manager_screen.dart';
import 'screens/teacher/assignments_manager_screen.dart';
import 'screens/teacher/students/students_list_screen.dart';
import 'screens/teacher/ai/teacher_ai_assistant_screen.dart';
import 'screens/teacher/videos/video_library_screen.dart';
import 'screens/teacher/videos/folder_videos_screen.dart';
import 'screens/teacher/videos/teacher_video_player_screen.dart';
import 'screens/teacher/chat/teacher_chat_screen.dart';
import 'screens/teacher/doubts/teacher_doubts_list_screen.dart';
import 'screens/teacher/doubts/teacher_doubt_detail_screen.dart';
import 'screens/teacher/schedule/schedule_screen.dart';
import 'models/teacher_video.dart';
import 'navigation/student_scaffold.dart';
import 'screens/student/dashboard_screen.dart';
import 'screens/student/notes_screen.dart';
import 'screens/student/assignments_screen.dart';
import 'screens/student/videos/folder_list_screen.dart';
import 'screens/student/videos/folder_detail_screen.dart';
import 'screens/student/videos/video_player_screen.dart';
import 'models/video.dart';
import 'screens/shared/contact_screen.dart';
import 'screens/student/quiz_screen.dart';
import 'screens/student/study_planner_screen.dart';
import 'models/doubt.dart';
import 'screens/student/doubts/doubts_list_screen.dart';
import 'screens/student/doubts/doubt_detail_screen.dart';
import 'screens/student/teachers_directory_screen.dart';
import 'screens/student/payments/payments_screen.dart';
import 'screens/student/profile_screen.dart';
import 'screens/shared/edit_profile_screen.dart';
import 'screens/shared/settings_screen.dart';
import 'screens/shared/legal_screen.dart';
import 'services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await CacheService.init();
  runApp(
    const ProviderScope(
      child: CoachingApp(),
    ),
  );
}

class CoachingApp extends ConsumerStatefulWidget {
  const CoachingApp({super.key});

  @override
  ConsumerState<CoachingApp> createState() => _CoachingAppState();
}

class _CoachingAppState extends ConsumerState<CoachingApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/student/quiz',
          builder: (context, state) => const QuizScreen(),
        ),
          GoRoute(
            path: '/student/study-planner',
            builder: (context, state) => const StudyPlannerScreen(),
          ),
        GoRoute(
          path: '/student/teachers',
          builder: (context, state) => const TeachersDirectoryScreen(),
        ),
        GoRoute(
          path: '/student/payments',
          builder: (context, state) => const PaymentsScreen(),
        ),
          GoRoute(
            path: '/student/profile',
            builder: (context, state) => const StudentProfileScreen(),
          ),
          GoRoute(
            path: '/shared/edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: '/shared/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/shared/legal',
            builder: (context, state) {
              final typeParam = state.uri.queryParameters['type'];
              LegalPolicyType initialType = LegalPolicyType.terms;
              if (typeParam == 'privacy') {
                initialType = LegalPolicyType.privacy;
              } else if (typeParam == 'refund') {
                initialType = LegalPolicyType.refund;
              } else if (typeParam == 'cookie') {
                initialType = LegalPolicyType.cookie;
              }
              return LegalScreen(initialPolicy: initialType);
            },
          ),
        GoRoute(
          path: '/student/doubts',
          builder: (context, state) => const DoubtsListScreen(),
        ),
        GoRoute(
          path: '/student/doubts/:id',
          builder: (context, state) {
            final doubt = state.extra is Doubt
                ? state.extra as Doubt
                : Doubt(
                    id: state.pathParameters['id'] ?? '',
                    title: 'Doubt Discussion',
                    description: '',
                    subject: 'General',
                    priority: 'normal',
                    status: 'OPEN',
                    isSolved: false,
                    upvotes: 0,
                    views: 0,
                    createdAt: DateTime.now().toIso8601String(),
                    student: DoubtUser(id: 'std', name: 'Student'),
                    isMyDoubt: true,
                    hasUpvoted: false,
                    stats: DoubtStats(totalReplies: 0, totalUpvotes: 0),
                    replies: [],
                  );
            return DoubtDetailScreen(initialDoubt: doubt);
          },
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return StudentScaffold(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/student/dashboard',
                  builder: (context, state) => const StudentDashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/student/notes',
                  builder: (context, state) => const NotesScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/student/assignments',
                  builder: (context, state) => const AssignmentsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/student/videos',
                  builder: (context, state) => const FolderListScreen(),
                  routes: [
                    GoRoute(
                      path: ':folderId',
                      builder: (context, state) {
                        final folder = state.extra is VideoFolder
                            ? state.extra as VideoFolder
                            : VideoFolder(
                                id: state.pathParameters['folderId'] ?? '',
                                name: 'Video Folder',
                                subject: 'General',
                                className: 'Class 12',
                                description: '',
                                thumbnail: '',
                                videoCount: 0,
                                totalDuration: '0m',
                                totalViews: 0,
                                teacher: 'Faculty',
                                teacherAvatar: '',
                                progress: 0,
                                completedCount: 0,
                                videos: [],
                              );
                        return FolderDetailScreen(folder: folder);
                      },
                      routes: [
                        GoRoute(
                          path: ':videoId',
                          builder: (context, state) {
                            final rawExtra = state.extra;
                            final args = rawExtra is Map
                                ? Map<String, dynamic>.from(rawExtra)
                                : <String, dynamic>{};
                            final video = args['video'] as VideoItem? ??
                                VideoItem(
                                  id: state.pathParameters['videoId'] ?? '',
                                  title: 'Video Lesson',
                                  description: '',
                                  duration: '0:00',
                                  views: 0,
                                  uploadDate: '',
                                  thumbnail: '',
                                  videoUrl: '',
                                  order: 0,
                                  watched: false,
                                  watchedPercentage: 0,
                                  watchedSeconds: 0,
                                  lastPosition: 0,
                                  bookmarked: false,
                                );
                            final folderName = args['folderName'] as String? ?? 'Video';
                            return VideoPlayerScreen(video: video, folderName: folderName);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/student/contact',
                  builder: (context, state) => const ContactScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/teacher',
          builder: (context, state) => const TeacherDashboardScreen(),
        ),
        GoRoute(
          path: '/teacher/schedule',
          builder: (context, state) => const ScheduleScreen(),
        ),
        GoRoute(
          path: '/teacher/notes',
          builder: (context, state) => const NotesManagerScreen(),
        ),
        GoRoute(
          path: '/teacher/assignments',
          builder: (context, state) => const AssignmentsManagerScreen(),
        ),
        GoRoute(
          path: '/teacher/students',
          builder: (context, state) => const StudentsListScreen(),
        ),
        GoRoute(
          path: '/teacher/ai-assistant',
          builder: (context, state) => const TeacherAIAssistantScreen(),
        ),
        GoRoute(
          path: '/teacher/chat',
          builder: (context, state) => const TeacherChatScreen(),
        ),
        GoRoute(
          path: '/teacher/doubts',
          builder: (context, state) => const TeacherDoubtsListScreen(),
          routes: [
            GoRoute(
              path: 'detail',
              builder: (context, state) {
                final extra = state.extra;
                final doubt = extra is Doubt
                    ? extra
                    : Doubt(
                        id: state.pathParameters['id'] ?? '',
                        title: 'Doubt Discussion',
                        description: '',
                        subject: 'General',
                        priority: 'normal',
                        status: 'OPEN',
                        isSolved: false,
                        upvotes: 0,
                        views: 0,
                        createdAt: DateTime.now().toIso8601String(),
                        student: DoubtUser(id: 'std', name: 'Student'),
                        isMyDoubt: false,
                        hasUpvoted: false,
                        stats: DoubtStats(totalReplies: 0, totalUpvotes: 0),
                        replies: [],
                      );
                return TeacherDoubtDetailScreen(doubt: doubt);
              },
            ),
          ]
        ),
        GoRoute(
          path: '/teacher/video-library',
          builder: (context, state) => const VideoLibraryScreen(),
          routes: [
            GoRoute(
              path: ':folderId',
              builder: (context, state) {
                final folder = state.extra as TeacherVideoFolder;
                return FolderVideosScreen(folder: folder);
              },
              routes: [
                GoRoute(
                  path: 'player',
                  builder: (context, state) {
                    final rawExtra = state.extra;
                    final extras = rawExtra is Map
                        ? Map<String, dynamic>.from(rawExtra)
                        : <String, dynamic>{};
                    return TeacherVideoPlayerScreen(
                      video: extras['video'],
                      queue: extras['queue'],
                      folderName: extras['folderName'],
                    );
                  },
                ),
              ]
            ),
          ]
        ),
        GoRoute(
          path: '/teacher/contact',
          builder: (context, state) => const ContactScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Admin Dashboard')),
            body: Center(
              child: ElevatedButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: const Text('Logout'),
              ),
            ),
          ),
        ),
      ],
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        if (!authState.isHydrated) return null;

        final isLoggingIn = state.uri.path == '/login';
        final isRegistering = state.uri.path == '/register';
        final isForgotPwd = state.uri.path == '/forgot-password';
        final isAuthRoute = isLoggingIn || isRegistering || isForgotPwd;
        
        if (authState.user == null && !isAuthRoute) {
          return '/login';
        }
        
        if (authState.user != null && isAuthRoute) {
          final role = authState.user!['role'];
          if (role == 'TEACHER') return '/teacher';
          if (role == 'ADMIN') return '/admin';
          return '/student/dashboard';
        }
        
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      _router.refresh();
    });

    final authState = ref.watch(authProvider);

    if (!authState.isHydrated) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        scrollBehavior: const SmoothAppScrollBehavior(),
        builder: (context, child) => GlassBackground(
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(
          backgroundColor: Colors.transparent,
          body: SizedBox.shrink(),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Intense Learners',
      routerConfig: _router,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      scrollBehavior: const SmoothAppScrollBehavior(),
      builder: (context, child) => GlassBackground(
        child: child ?? const SizedBox.shrink(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SmoothAppScrollBehavior extends MaterialScrollBehavior {
  const SmoothAppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}
