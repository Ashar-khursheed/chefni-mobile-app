import 'package:flutter/material.dart';

import '../network/api_client.dart';
import '../repositories/admin_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/branding_repository.dart';
import '../repositories/haccp_repository.dart';
import '../repositories/inventory_repository.dart';
import '../repositories/legal_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/recipe_card_repository.dart';
import '../repositories/recipe_repository.dart';
import '../repositories/reel_repository.dart';
import '../repositories/shopping_repository.dart';
import '../repositories/store_repository.dart';
import '../repositories/studio_repository.dart';
import '../repositories/subscription_repository.dart';
import '../repositories/team_repository.dart';

/// Single wiring point for the API client and repositories.
class Services {
  Services({ApiClient? apiClient}) : api = apiClient ?? ApiClient() {
    auth = AuthRepository(api);
    recipes = RecipeRepository(api);
    shopping = ShoppingRepository(api);
    subscriptions = SubscriptionRepository(api);
    reels = ReelRepository(api);
    inventory = InventoryRepository(api);
    admin = AdminRepository(api);
    studio = StudioRepository(api);
    recipeCards = RecipeCardRepository(api);
    legal = LegalRepository(api);
    notifications = NotificationRepository(api);
    team = TeamRepository(api);
    haccp = HaccpRepository(api);
    branding = BrandingRepository(api);
    stores = StoreRepository(api);
  }

  final ApiClient api;

  late final AuthRepository auth;
  late final RecipeRepository recipes;
  late final ShoppingRepository shopping;
  late final SubscriptionRepository subscriptions;
  late final ReelRepository reels;
  late final InventoryRepository inventory;
  late final AdminRepository admin;
  late final StudioRepository studio;
  late final RecipeCardRepository recipeCards;
  late final LegalRepository legal;
  late final NotificationRepository notifications;
  late final TeamRepository team;
  late final HaccpRepository haccp;
  late final BrandingRepository branding;
  late final StoreRepository stores;

  void dispose() => api.close();
}

class ServiceScope extends InheritedWidget {
  const ServiceScope({
    super.key,
    required this.services,
    required super.child,
  });

  final Services services;

  static Services of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ServiceScope>();
    assert(scope != null, 'ServiceScope is missing from the widget tree.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(ServiceScope oldWidget) =>
      services != oldWidget.services;
}
