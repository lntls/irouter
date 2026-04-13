part of 'router.dart';

final class IPageBuilder {
  IPageBuilder.custom(this._creator);

  final Route<Object?> Function(BuildContext, Page<Object?>, Widget) _creator;

  @internal
  Route<Object?> createRoute(
    BuildContext context,
    Page<Object?> page,
    Widget content,
  ) {
    return _creator(context, page, content);
  }
}

final class IRouteEntry<R, A> {
  const IRouteEntry._(this._route, this._args);

  final IRoute<R, A> _route;

  final A _args;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IRouteEntry && _route == other._route && _args == other._args;

  @override
  int get hashCode => Object.hash(_route, _args);
}

final class IRoute<R, A> {
  IRoute._({
    required Widget Function(BuildContext, A) widgetBuilder,
    IPageBuilder? pageBuilder,
  }) : _widgetBuilder = widgetBuilder,
       _pageBuilder = pageBuilder;

  final IPageBuilder? _pageBuilder;

  final Widget Function(BuildContext, A) _widgetBuilder;
}

extension IRouteWithArgsExtension<R, A extends Object?> on IRoute<R, A> {
  IRouteEntry<R, A> call(A args) => IRouteEntry._(this, args);
}

extension IRouteWithoutArgsExtension<R> on IRoute<R, Never> {
  IRouteEntry<R, void> call() => IRouteEntry._(this, null);
}

final class IRouteBuilder<R> {
  IRouteBuilder._({required this.pageBuilder});

  IPageBuilder? pageBuilder;

  IRouteBuilder<T> withResult<T>() {
    return IRouteBuilder._(pageBuilder: pageBuilder);
  }
}

extension IRouteBuilderWithArgsExtension<R> on IRouteBuilder<R> {
  IRoute<R, Never> build(Widget Function(BuildContext) builder) {
    return IRoute._(
      pageBuilder: pageBuilder,
      widgetBuilder: (context, _) => builder(context),
    );
  }

  IRoute<R, A> buildWith<A extends Object?>(
    Widget Function(BuildContext, A) builder,
  ) {
    return IRoute._(
      pageBuilder: pageBuilder,
      widgetBuilder: (context, args) => builder(context, args),
    );
  }
}

final class IRouteFactory {
  IRouteFactory._();

  IRouteBuilder<void> call<R, A>({IPageBuilder? routeBuilder}) {
    return IRouteBuilder._(pageBuilder: routeBuilder);
  }
}
