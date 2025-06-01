
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/navigation_service.dart';

part 'navigation_provider.g.dart';


@riverpod
NavigationService navigationService(Ref ref) {
  return NavigationService();
}
