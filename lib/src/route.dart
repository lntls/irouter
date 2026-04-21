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

  Widget _buildContent(BuildContext context) {
    return _route._widgetBuilder(context, _args);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IRouteEntry && _route == other._route && _args == other._args;

  @override
  int get hashCode => Object.hash(_route, _args);
}

abstract class IRoute<R, A> {
  IRoute._({
    required Widget Function(BuildContext, A) widgetBuilder,
    IPageBuilder? pageBuilder,
  }) : _widgetBuilder = widgetBuilder,
       _pageBuilder = pageBuilder;

  final IPageBuilder? _pageBuilder;

  final Widget Function(BuildContext, A) _widgetBuilder;
}

class IRouteWithArgs<R, A extends Object?> extends IRoute<R, A> {
  IRouteWithArgs._({required super.widgetBuilder, super.pageBuilder})
    : super._();

  IRouteEntry<R, A> call(A args) {
    return IRouteEntry._(this, args);
  }
}

class IRouteWithoutArgs<R> extends IRoute<R, void> {
  IRouteWithoutArgs._({required super.widgetBuilder, super.pageBuilder})
    : super._();

  IRouteEntry<R, void> call() {
    return IRouteEntry._(this, null);
  }
}

final class IRouteBuilder<R> {
  IRouteBuilder._({required this.pageBuilder});

  IPageBuilder? pageBuilder;

  IRouteBuilder<T> withResult<T>() {
    return IRouteBuilder._(pageBuilder: pageBuilder);
  }
}

extension IRouteBuilderWithArgsExtension<R> on IRouteBuilder<R> {
  IRouteWithoutArgs<R> build(Widget Function(BuildContext) builder) {
    return IRouteWithoutArgs._(
      pageBuilder: pageBuilder,
      widgetBuilder: (context, _) => builder(context),
    );
  }

  IRouteWithArgs<R, A> buildWith<A extends Object?>(
    Widget Function(BuildContext, A) builder,
  ) {
    return IRouteWithArgs._(
      pageBuilder: pageBuilder,
      widgetBuilder: (context, args) => builder(context, args),
    );
  }
}

final class IRouteFactory {
  IRouteFactory._();

  IRouteBuilder<void> call({IPageBuilder? pageBuilder}) {
    return IRouteBuilder._(pageBuilder: pageBuilder);
  }
}
