import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreviousPageIndex extends Notifier<List<int>> {
  @override
  List<int> build() {
    return [0];
  }

  void currentIndex(int pageIndex) {
    if (state.length >= 5) {
      debugPrint('before transform index is $state');
      state.remove(state.elementAt(0));
      state.add(pageIndex);
      debugPrint(' after transform previous page index is $state');
    } else {
      state.add(pageIndex);
      debugPrint('previous page index is $state');
    }
  }
}
