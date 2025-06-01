import '../../features/home/presentation/routing/home_router_config.dart';

// ignore_for_file: unused_import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import './routes_constants.dart';
import '../../features/home/presentation/routing/home_routes_constants.dart';

part 'router_config.g.dart';
 
@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    // observers: [TalkerRouteObserver(log.talker)],
    initialLocation: HomeRoutes.homePath,
    routes: [
			...getHomeRoutes(),
        
    ]); 
}   

