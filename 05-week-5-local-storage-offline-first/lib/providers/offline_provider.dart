import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setOffline(bool value) {
    state = value;
  }
}

final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);