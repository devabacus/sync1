
import '../../presentation/pages/home_page.dart';
import 'home_routes_constants.dart';

import 'dart:core';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


List<RouteBase> getHomeRoutes() {
  return [
    GoRoute(
      name: HomeRoutes.home,
      path: HomeRoutes.homePath,
      builder: (BuildContext context, state) => HomePage(),
    ),
  ];
}
