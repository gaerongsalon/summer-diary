import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

typedef SimpleBlocEventHandler<Event> = Future<void> Function(Event);

abstract class SimpleBlocStateMachine<Event, State, Side>
    extends Bloc<Event, State> {
  final _sideState = StreamController<Side>();
  bool _busy = false;

  bool get busy => this._busy;

  @override
  void dispose() {
    // If it is "this._sideStream", the linter warns that it is not closed.
    /* this. */ _sideState.close();
    super.dispose();
  }

  @override
  Stream<State> mapEventToState(Event event) async* {
    if (!this.alive) {
      print('This state machine is dead, so I cannot serve this event: $event');
      return;
    }
    final handler = this.routes[event.runtimeType];
    if (handler == null) {
      throw new Exception(
          'No handler mapped with ' + event.runtimeType.toString());
    }
    this._busy = true;
    try {
      await handler(event);
      yield this.buildCurrentState();
      await this.onAfterYield(event);
    } finally {
      this._busy = false;
    }
  }

  @protected
  bool get alive => true;

  @protected
  Map<Type, Future<void> Function(Event)> get routes;

  @protected
  State buildCurrentState();

  Stream<Side> get sideState {
    return this._sideState.stream;
  }

  @protected
  void publishSide(Side side) {
    this._sideState.add(side);
  }

  @protected
  Future<void> onAfterYield(Event event) async {}
}
