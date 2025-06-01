import '../../features/home/presentation/routing/home_routes_constants.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {

    void navigateToHome(BuildContext context) {
      context.goNamed(HomeRoutes.home);
    }
  
}
