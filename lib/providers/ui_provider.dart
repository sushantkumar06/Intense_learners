import 'package:flutter_riverpod/flutter_riverpod.dart';

class UIState {
  final String viewMode;

  UIState({this.viewMode = 'student'});

  UIState copyWith({String? viewMode}) {
    return UIState(viewMode: viewMode ?? this.viewMode);
  }
}

class UINotifier extends Notifier<UIState> {
  @override
  UIState build() {
    return UIState();
  }

  void setViewMode(String mode) {
    state = state.copyWith(viewMode: mode);
  }
}

final uiProvider = NotifierProvider<UINotifier, UIState>(() {
  return UINotifier();
});
