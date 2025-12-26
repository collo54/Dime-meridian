import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PageIndex extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void currentIndex(int messageResponse) {
    state = messageResponse;
    debugPrint('current page index :$state');
  }
}
