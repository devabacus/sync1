
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/home_navigation_service.dart';

part 'home_navigation_provider.g.dart';

@riverpod
HomeNavigationService homeNavigationService(Ref ref) {
  return HomeNavigationService();
}

