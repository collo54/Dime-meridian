import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

class NewModelUserNotifier extends Notifier<List<UserModel>> {
  @override
  List<UserModel> build() {
    return [];
  }

  void updateUserModel(UserModel userModel) {
    state = [...state, userModel];
    debugPrint('current userModel Uid :${state.length}');
  }

  void claerUserModel() {
    state = [];
    debugPrint('clear userModel Uid :${state.length}');
  }
}
