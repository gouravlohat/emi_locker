import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/local_storage.dart';

// Theme mode
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final isDark = LocalStorage().isDarkMode;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    await LocalStorage().setDarkMode(newMode == ThemeMode.dark);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await LocalStorage().setDarkMode(mode == ThemeMode.dark);
  }
}

// Connectivity
final connectivityProvider = StateProvider<bool>((ref) => true);

// App initialization state
class AppInitState {
  final bool isInitialized;
  final bool isEnrolled;
  final bool isLoggedIn;
  final bool isDeviceLocked;

  const AppInitState({
    this.isInitialized = false,
    this.isEnrolled = false,
    this.isLoggedIn = false,
    this.isDeviceLocked = false,
  });
}

class AppInitNotifier extends AsyncNotifier<AppInitState> {
  @override
  Future<AppInitState> build() async {
    await LocalStorage().init();
    final localStorage = LocalStorage();
    return AppInitState(
      isInitialized: true,
      isEnrolled: localStorage.isEnrolled,
      isLoggedIn: localStorage.isLoggedIn,
      isDeviceLocked: localStorage.isDeviceLocked,
    );
  }

  Future<void> markEnrolled() async {
    await LocalStorage().setEnrolled(true);
    state = AsyncData(state.value!.copyWith(isEnrolled: true));
  }

  void refresh() {
    final localStorage = LocalStorage();
    state = AsyncData(AppInitState(
      isInitialized: true,
      isEnrolled: localStorage.isEnrolled,
      isLoggedIn: localStorage.isLoggedIn,
      isDeviceLocked: localStorage.isDeviceLocked,
    ));
  }
}

extension on AppInitState {
  AppInitState copyWith({
    bool? isInitialized,
    bool? isEnrolled,
    bool? isLoggedIn,
    bool? isDeviceLocked,
  }) =>
      AppInitState(
        isInitialized: isInitialized ?? this.isInitialized,
        isEnrolled: isEnrolled ?? this.isEnrolled,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        isDeviceLocked: isDeviceLocked ?? this.isDeviceLocked,
      );
}

final appInitProvider = AsyncNotifierProvider<AppInitNotifier, AppInitState>(AppInitNotifier.new);

// Notification badge count
final notificationCountProvider = StateProvider<int>((ref) => 3);

// Bottom nav index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');
