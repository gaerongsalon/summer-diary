import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

typedef BlocEventHandler<Event, State> = Future<State> Function(Event);

abstract class BlocStateMachine<Event, State> extends Bloc<Event, State> {
  Map<Type /* StateType */,
      Map<Type /* EventType */, BlocEventHandler<Event, State>>> _dispatcher;

  BlocStateMachine() : super() {
    this._dispatcher = this.generateDispatcher();
  }

  @override
  Stream<State> mapEventToState(Event event) async* {
    if (!this.alive) {
      print('This state machine is dead, so I cannot serve this event: $event');
      return;
    }
    final stateType = currentState.runtimeType;
    final eventType = event.runtimeType;

    final handlers = this._dispatcher[stateType];
    if (handlers == null) {
      throw new Exception('No handler mapped with State[$stateType]');
    }
    final handler = handlers[eventType];
    if (handler == null) {
      throw new Exception(
          'No handler mapped with State[$stateType] -> Event[$eventType]');
    }
    yield await handler(event);
    await this.onAfterYield(event);
  }

  @protected
  bool get alive => true;

  @protected
  Map<Type /* StateType */,
          Map<Type /* EventType */, BlocEventHandler<Event, State>>>
      generateDispatcher();

  @protected
  Future<void> onAfterYield(Event event) async {}
}
