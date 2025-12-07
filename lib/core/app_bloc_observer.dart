import 'dart:developer';

import 'package:bloc/bloc.dart';

/// A custom BlocObserver that provides enhanced logging and error handling
/// for BLoC state changes and events throughout the application.
class AppBlocObserver extends BlocObserver {
  final bool _logStateChanges;
  final bool _logEvents;
  final bool _logTransitions;
  final bool _logErrors;

  /// Creates an [AppBlocObserver] with configurable logging options.
  ///
  /// - [logStateChanges]: Whether to log state changes (default: true)
  /// - [logEvents]: Whether to log events (default: false)
  /// - [logTransitions]: Whether to log transitions (default: true)
  /// - [logErrors]: Whether to log errors (default: true)
  AppBlocObserver({
    bool logStateChanges = true,
    bool logEvents = false,
    bool logTransitions = true,
    bool logErrors = true,
  })  : _logStateChanges = logStateChanges,
        _logEvents = logEvents,
        _logTransitions = logTransitions,
        _logErrors = logErrors;

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);

    if (_logStateChanges) {
      _logStateChange(bloc, change);
    }
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);

    if (_logEvents && event != null) {
      log(
        'Event: ${bloc.runtimeType} - ${event.runtimeType}',
        name: 'bloc',
        level: 500, // FINE level
      );
    }
  }

  @override
  void onTransition(
      Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    super.onTransition(bloc, transition);

    if (_logTransitions) {
      _logTransition(bloc, transition);
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    if (_logErrors) {
      _logError(bloc, error, stackTrace);
    }
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    log(
      'BLoC Closed: ${bloc.runtimeType}',
      name: 'bloc',
      level: 800, // INFO level
    );
    super.onClose(bloc);
  }

  void _logStateChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    final currentState = change.currentState;
    final nextState = change.nextState;

    log(
      '\nState Change: ${bloc.runtimeType}\n'
      '  Current: ${_formatState(currentState)}\n'
      '  \n'
      '  Next: ${_formatState(nextState)}'
      '  \n',
      name: 'bloc',
      level: 800, // INFO level
    );
  }

  void _logTransition(
      Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    final event = transition.event;
    final currentState = transition.currentState;
    final nextState = transition.nextState;

    log(
      'Transition: ${bloc.runtimeType}\n'
      '  Event: ${event.runtimeType}\n'
      '  Current: ${_formatState(currentState)}\n'
      '  Next: ${_formatState(nextState)}',
      name: 'bloc',
      level: 500, // FINE level
    );
  }

  void _logError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log(
      'Error in ${bloc.runtimeType}: $error',
      name: 'bloc',
      level: 1200, // SEVERE level
      error: error,
      stackTrace: stackTrace,
    );
  }

  String _formatState(dynamic state) {
    if (state == null) return 'null';

    final stateString = state.toString();
    // Truncate very long state strings for better readability
    if (stateString.length > 200) {
      return '${stateString.substring(0, 200)}...';
    }
    return stateString;
  }

  /// A simple factory method for quick initialization with default settings
  static AppBlocObserver get defaultObserver => AppBlocObserver();

  /// A factory method for production use with minimal logging
  static AppBlocObserver get productionObserver => AppBlocObserver(
        logStateChanges: false,
        logEvents: false,
        logTransitions: false,
        logErrors: true, // Keep error logging enabled in production
      );

  /// A factory method for development with verbose logging
  static AppBlocObserver get developmentObserver => AppBlocObserver(
        logStateChanges: true,
        logEvents: true,
        logTransitions: true,
        logErrors: true,
      );
}
