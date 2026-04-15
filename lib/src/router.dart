import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

part 'route.dart';

abstract interface class IRoutingController<T extends Record> {
  RouterConfig<Object> get config;

  Future<R> push<R, A extends Record>(IRouteEntry<R, A> Function(T) selector);

  bool get canPop;

  void pop();

  void dispose();
}

class _IRouteInformationParser
    extends RouteInformationParser<RouteInformation> {
  @override
  Future<RouteInformation> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    return SynchronousFuture(routeInformation);
  }
}

class _IPage<R, A extends Record> extends Page<Object?> {
  _IPage({required this.pageBuilder, required this.entry, super.onPopInvoked})
    : super(key: ValueKey(entry));

  final IPageBuilder pageBuilder;
  final IRouteEntry<R, A> entry;

  @override
  Route<Object?> createRoute(BuildContext context) {
    final content = entry._buildContent(context);
    final pageBuilder = entry._route._pageBuilder ?? this.pageBuilder;
    return pageBuilder.createRoute(context, this, content);
  }
}

class _InheritedRoutingController<T extends Record> extends InheritedWidget {
  const _InheritedRoutingController({
    super.key,
    required super.child,
    required this.controller,
  });

  final IRoutingController<T> controller;

  @override
  bool updateShouldNotify(_InheritedRoutingController<T> oldWidget) {
    return oldWidget.controller != controller;
  }
}

extension _IRouteEntryExtension<R, A extends Record> on IRouteEntry<R, A> {
  _IPage<R, A> toPage(IPageBuilder defaultPageBuilder) {
    return _IPage(pageBuilder: defaultPageBuilder, entry: this);
  }
}

class _IRouterDelegate<T extends Record>
    extends RouterDelegate<RouteInformation>
    with ChangeNotifier
    implements IRoutingController<T> {
  _IRouterDelegate({
    required T Function(IRouteFactory) routes,
    required this.defaultPageBuilder,
    required List<IRouteEntry<Object?, Record>> Function(T) initialRoutes,
  }) : _definedRoutes = routes(IRouteFactory._()) {
    _pages = initialRoutes(_definedRoutes)
        .map((entry) => entry.toPage(defaultPageBuilder))
        .toList();
  }

  final IPageBuilder defaultPageBuilder;

  final T _definedRoutes;

  late List<Page<Object?>> _pages;

  void _onDidRemovePage(Page<Object?> page) {
    _pages.remove(page);
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedRoutingController<T>(
      controller: this,
      child: Navigator(pages: _pages, onDidRemovePage: _onDidRemovePage),
    );
  }

  @override
  Future<R> push<R, A extends Record>(IRouteEntry<R, A> Function(T) selector) async {
    final resultCompleter = Completer<R>();
    final entry = selector(_definedRoutes);
    final newPage = _IPage(
      pageBuilder: defaultPageBuilder,
      entry: entry,
      onPopInvoked: (didPop, result) {
        if (didPop) {
          resultCompleter.complete(result as R);
        }
      },
    );
    _pages.removeWhere((page) => page.key == newPage.key);
    _pages = [..._pages, newPage];
    notifyListeners();
    return resultCompleter.future;
  }

  @override
  bool get canPop => _pages.length > 1;

  void _pop() {
    _pages = _pages.sublist(0, _pages.length - 1);
    _pages.removeLast();
    notifyListeners();
  }

  @override
  void pop() {
    if (canPop) {
      _pop();
    }
  }

  @override
  Future<bool> popRoute() {
    if (!canPop) {
      return SynchronousFuture(false);
    }
    _pages = _pages.sublist(0, _pages.length - 1);
    _pages.removeLast();
    notifyListeners();
    return SynchronousFuture(true);
  }

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) {
    return SynchronousFuture(null);
  }

  @override
  late final RouterConfig<Object> config = RouterConfig<RouteInformation>(
    routerDelegate: this,
    routeInformationProvider: PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
    ),
    routeInformationParser: _IRouteInformationParser(),
  );
}

abstract base class IRouter<T extends Record> {
  IRouter._();

  factory IRouter({
    required IPageBuilder pageBuilder,
    required T Function(IRouteFactory) routes,
    required List<IRouteEntry<Object?, Record>> Function(T) initialRoutes,
  }) = _IRouter;

  IRoutingController<T> createRoutingController();

  IRoutingController<T> of(BuildContext context);
}

final class _IRouter<T extends Record> extends IRouter<T> {
  _IRouter({
    required this.routes,
    required this.pageBuilder,
    required this.initialRoutes,
  }) : super._();

  final IPageBuilder pageBuilder;

  final T Function(IRouteFactory) routes;

  final List<IRouteEntry<Object?, Record>> Function(T) initialRoutes;

  @override
  IRoutingController<T> of(BuildContext context) {
    final widget = context
        .getInheritedWidgetOfExactType<_InheritedRoutingController<T>>();
    return widget!.controller;
  }

  @override
  IRoutingController<T> createRoutingController() {
    return _IRouterDelegate(
      routes: routes,
      defaultPageBuilder: pageBuilder,
      initialRoutes: initialRoutes,
    );
  }
}
