import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'nav_utils.dart';

typedef NavigationTypeResolver = NavigationType Function(BuildContext context);

// The navigation mechanism to configure the [Scaffold] with.
enum NavigationType {
  // Used to configure a [Scaffold] with a [BottomNavigationBar].
  bottom,

  // Used to configure a [Scaffold] with a [NavigationRail].
  rail,

  // Used to configure a [Scaffold] with a modal [Drawer].
  drawer,

  // Used to configure a [Scaffold] with an always open [Drawer].
  permanentDrawer,
}

/// Used to configure items or destinations in the various navigation
/// mechanism. For [BottomNavigationBar], see [BottomNavigationBarItem]. For
/// [NavigationRail], see [NavigationRailDestination]. For [Drawer], see
/// [ListTile].
class AdaptiveDestination {
  final String title;
  final IconData icon;

  AdaptiveDestination({required this.title, required this.icon});
}

/// A widget that adapts to the current display size, displaying a [Drawer],
/// [NavigationRail], or [BottomNavigationBar]. Navigation destinations are
/// defined in the [destinations] parameter.
class AdaptiveNavigation extends StatelessWidget {
  /// See [Scaffold.appBar].
  final PreferredSizeWidget? appBar;

  /// See [Scaffold.body].
  final Widget body;

  /// See [Scaffold.floatingActionButton].
  final FloatingActionButton? floatingActionButton;

  /// See [Scaffold.floatingActionButtonLocation].
  ///
  /// Ignored if [fabInRail] is true.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// See [Scaffold.floatingActionButtonAnimator].
  ///
  /// Ignored if [fabInRail] is true.
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;

  /// See [Scaffold.persistentFooterButtons].
  final List<Widget>? persistentFooterButtons;

  /// See [Scaffold.endDrawer].
  final Widget? endDrawer;

  /// See [Scaffold.drawerScrimColor].
  final Color? drawerScrimColor;

  /// See [Scaffold.backgroundColor].
  final Color? backgroundColor;

  /// See [Scaffold.bottomSheet].
  final Widget? bottomSheet;

  /// See [Scaffold.resizeToAvoidBottomInset].
  final bool? resizeToAvoidBottomInset;

  /// See [Scaffold.primary].
  final bool primary;

  /// See [Scaffold.extendBody].
  final bool extendBody;

  /// See [Scaffold.extendBodyBehindAppBar].
  final bool extendBodyBehindAppBar;

  /// See [Scaffold.drawerEdgeDragWidth].
  final double? drawerEdgeDragWidth;

  /// See [Scaffold.drawerEnableOpenDragGesture].
  final bool drawerEnableOpenDragGesture;

  /// See [Scaffold.endDrawerEnableOpenDragGesture].
  final bool endDrawerEnableOpenDragGesture;

  /// The index into [destinations] for the current selected
  /// [AdaptiveScaffoldDestination].
  final int selectedIndex;

  /// Defines the appearance of the items that are arrayed within the
  /// navigation.
  ///
  /// The value must be a list of two or more [AdaptiveScaffoldDestination]
  /// values.
  final List<AdaptiveDestination> destinations;

  /// Called when one of the [destinations] is selected.
  ///
  /// The stateful widget that creates the adaptive scaffold needs to keep
  /// track of the index of the selected [AdaptiveScaffoldDestination] and call
  /// `setState` to rebuild the adaptive scaffold with the new [selectedIndex].
  final ValueChanged<int>? onDestinationSelected;

  /// Determines the navigation type that the scaffold uses.
  final NavigationTypeResolver? navigationTypeResolver;

  /// The leading item in the drawer when the navigation has a drawer.
  ///
  /// If null, then there is no header.
  final Widget? drawerHeader;

  /// Whether the [floatingActionButton] is inside or the rail or in the regular
  /// spot.
  ///
  /// If true, then [floatingActionButtonLocation] and
  /// [floatingActionButtonAnimation] are ignored.
  final bool fabInRail;

  /// Weather the overflow menu defaults to include overflow destinations and
  /// the overflow destinations.
  final bool includeBaseDestinationsInMenu;

  const AdaptiveNavigation({
    Key? key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.endDrawer,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    required this.selectedIndex,
    required this.destinations,
    this.onDestinationSelected,
    this.navigationTypeResolver,
    this.drawerHeader,
    this.fabInRail = true,
    this.includeBaseDestinationsInMenu = true,
  }) : super(key: key);

  NavigationType _defaultNavigationTypeResolver(BuildContext context) {
    if (_isLargeScreen(context)) {
      return NavigationType.permanentDrawer;
    } else if (_isMediumScreen(context)) {
      return NavigationType.rail;
    } else {
      return NavigationType.bottom;
    }
  }

  Drawer _defaultDrawer(
      List<AdaptiveDestination> destinations, BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          if (drawerHeader != null) drawerHeader!,
          for (int i = 0; i < destinations.length; i++)
            ListTile(
              leading: Icon(destinations[i].icon),
              title: Text(destinations[i].title),
              onTap: () {
                onDestinationSelected?.call(i);
                Navigator.pop(context);
              },
            )
        ],
      ),
    );
  }

  Widget _buildEmptyNavigationScaffold() {
    return Scaffold(
      key: key,
      body: body,
    );
  }

  Widget _buildBottomNavigationScaffold(BuildContext context) {
    const int bottomNavigationOverflow = 4;
    final bottomDestinations = destinations.sublist(
      0,
      math.min(destinations.length, bottomNavigationOverflow),
    );
    final drawerDestinations = destinations.length > bottomNavigationOverflow
        ? destinations.sublist(
            includeBaseDestinationsInMenu ? 0 : bottomNavigationOverflow)
        : <AdaptiveDestination>[];
    return Scaffold(
      key: key,
      body: body,
      appBar: appBar,
      drawer: drawerDestinations.isEmpty
          ? null
          : _defaultDrawer(drawerDestinations, context),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          for (final destination in bottomDestinations)
            BottomNavigationBarItem(
              icon: Icon(destination.icon),
              label: destination.title,
            ),
        ],
        currentIndex: selectedIndex,
        onTap: onDestinationSelected ?? (_) {},
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildNavigationRailScaffold(BuildContext context) {
    const int railDestinationsOverflow = 7;
    final railDestinations = destinations.sublist(
        0, math.min(destinations.length, railDestinationsOverflow));
    final drawerDestinations = destinations
        .sublist(includeBaseDestinationsInMenu ? 0 : railDestinationsOverflow);
    // final drawerDestinations = destinations.length > railDestinationsOverflow
    //     ? destinations.sublist(
    //         includeBaseDestinationsInMenu ? 0 : railDestinationsOverflow)
    //     : <AdaptiveDestination>[];
    return Scaffold(
      key: key,
      appBar: appBar,
      drawer: drawerDestinations.isEmpty
          ? null
          : _defaultDrawer(drawerDestinations, context),
      body: Row(
        children: [
          NavigationRail(
            leading: fabInRail ? floatingActionButton : null,
            destinations: [
              for (final destination in railDestinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  label: Text(destination.title),
                ),
            ],
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected ?? (_) {},
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
          ),
          Expanded(
            child: body,
          ),
        ],
      ),
      floatingActionButton: fabInRail ? null : floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons,
      endDrawer: endDrawer,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: true,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawerScrimColor: drawerScrimColor,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
    );
  }

  Widget _buildNavigationDrawerScaffold() {
    return Scaffold(
      key: key,
      body: body,
      appBar: appBar,
      drawer: Drawer(
        child: Column(
          children: [
            // TODO: Find a better way to write `drawerHeader!`
            if (drawerHeader != null) drawerHeader!,
            for (final destination in destinations)
              ListTile(
                leading: Icon(destination.icon),
                title: Text(destination.title),
                selected: destinations.indexOf(destination) == selectedIndex,
                onTap: () => _destinationTapped(destination),
              ),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons,
      endDrawer: endDrawer,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: true,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawerScrimColor: drawerScrimColor,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
    );
  }

  Widget _buildPermanentDrawerScaffold() {
    return Row(
      children: [
        Drawer(
          child: Column(
            children: [
              // TODO: Find a better way to write `drawerHeader!`
              if (drawerHeader != null) drawerHeader!,
              for (final destination in destinations)
                ListTile(
                  leading: Icon(destination.icon),
                  title: Text(destination.title),
                  selected: destinations.indexOf(destination) == selectedIndex,
                  onTap: () => _destinationTapped(destination),
                ),
            ],
          ),
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
        ),
        Expanded(
          child: Scaffold(
            key: key,
            appBar: appBar,
            body: body,
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
            floatingActionButtonAnimator: floatingActionButtonAnimator,
            persistentFooterButtons: persistentFooterButtons,
            endDrawer: endDrawer,
            bottomSheet: bottomSheet,
            backgroundColor: backgroundColor,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
            primary: true,
            extendBody: extendBody,
            extendBodyBehindAppBar: extendBodyBehindAppBar,
            drawerScrimColor: drawerScrimColor,
            drawerEdgeDragWidth: drawerEdgeDragWidth,
            drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
            endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final NavigationTypeResolver navigationTypeResolver =
        this.navigationTypeResolver ?? _defaultNavigationTypeResolver;
    final navigationType = navigationTypeResolver(context);

    switch (navigationType) {
      case NavigationType.bottom:
        {
          if (hideBottomAndTopBarOn
              .contains(AutoRouter.of(context).topRoute.name)) {
            return _buildEmptyNavigationScaffold();
          } else {
            return _buildBottomNavigationScaffold(context);
          }
        }
      case NavigationType.rail:
        return _buildNavigationRailScaffold(context);
      case NavigationType.drawer:
        return _buildNavigationDrawerScaffold();
      case NavigationType.permanentDrawer:
        return _buildPermanentDrawerScaffold();
    }
  }

  void _destinationTapped(AdaptiveDestination destination) {
    final index = destinations.indexOf(destination);
    if (index != selectedIndex) {
      onDestinationSelected?.call(index);
    }
  }
}

bool _isLargeScreen(BuildContext context) {
  return MediaQuery.of(context).size.width > 1080.0;
}

bool _isMediumScreen(BuildContext context) {
  return MediaQuery.of(context).size.width > 640.0;
}
