import 'package:flutter/material.dart';

/// Root Navigator handle, attached to MaterialApp in app.dart - lets code
/// outside the widget tree (PushNotificationService, reacting to a
/// notification tap) push a route without a BuildContext of its own.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
