import 'package:flutter/material.dart';

import '../../core/errors/error_handler.dart';
import 'empty_state.dart';
import 'error_state.dart';
import 'loading_state.dart';

/// Loads data with [load] and renders loading / error (with retry) / empty /
/// data states consistently across the app.
///
/// Screens pass a repository call; no try/catch or spinners in UI code:
/// ```dart
/// AsyncView<List<CourseModel>>(
///   load: () => context.read<CourseRepository>().getStudentCourses(id),
///   isEmpty: (courses) => courses.isEmpty,
///   builder: (context, courses, reload) => ...,
/// )
/// ```
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.isEmpty,
    this.empty,
    this.loading,
    this.errorCompact = false,
  });

  final Future<T> Function() load;

  /// `reload` re-runs [load]; returns a future suitable for RefreshIndicator.
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() reload,
  )
  builder;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Widget? loading;
  final bool errorCompact;

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _loading = !_hasData;
      _error = null;
    });
    try {
      final data = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _hasData = true;
        _loading = false;
      });
    } on Object catch (e, stack) {
      ErrorHandler.log(e, stack);
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return widget.loading ?? const LoadingState();
    if (_error != null && !_hasData) {
      return ErrorState(
        error: _error,
        onRetry: reload,
        compact: widget.errorCompact,
      );
    }
    final data = _data as T;
    if (widget.isEmpty?.call(data) ?? false) {
      return widget.empty ??
          const EmptyState(
            title: 'Nothing here yet',
            message: 'There is no data to show at the moment.',
          );
    }
    return widget.builder(context, data, reload);
  }
}
