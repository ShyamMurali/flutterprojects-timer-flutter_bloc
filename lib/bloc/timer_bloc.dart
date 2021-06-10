import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:timer_flutter_bloc/ticker.dart';


part 'timer_event.dart';
part 'timer_state.dart';


// If the TimerBloc receives a TimerStarted event, it pushes a TimerRunInProgressstate
// with the start duration. In addition, if there was already an open _tickerSubscription
//  we need to cancel it to deallocate the memory. We also need to override the close
//  method on our TimerBloc so that we can cancel the _tickerSubscription when the 
// TimerBloc is closed. Lastly, we listen to the _ticker.tick stream and on every tick 
// we add a TimerTicked event with the remaining duration.


// Every time a TimerTicked event is received, if the tick’s duration is greater than 0,
//  we need to push an updated TimerRunInProgress state with the new duration.
//  Otherwise, if the tick’s duration is 0, our timer has ended and
//  we need to push a TimerRunComplete state.

// In _mapTimerPausedToState if the state of our TimerBloc is TimerRunInProgress,
//  then we can pause the _tickerSubscription and 
// push a TimerRunPause state with the current timer duration.

// The TimerResumed event handler is very similar to the TimerPaused event handler.
//  If the TimerBloc has a state of TimerRunPause and it receives a TimerResumed event,
//  then it resumes the _tickerSubscription and pushes a TimerRunInProgress state with
//  the current duration.

// if the TimerBloc receives a TimerReset event, it needs to cancel the current _tickerSubscription
//  so that it isn’t notified of any additional ticks and pushes a TimerInitial state with the original duration.

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  final Ticker _ticker;
  static const int _duration = 60;

  StreamSubscription<int> _tickerSubscription;

  TimerBloc({ Ticker ticker})
      : _ticker = ticker,
        super(TimerInitial(_duration));

  @override
  Stream<TimerState> mapEventToState(
    TimerEvent event,
  ) async* {
    if (event is TimerStarted) {
      yield* _mapTimerStartedToState(event);
    } else if (event is TimerPaused) {
      yield* _mapTimerPausedToState(event);
    } else if (event is TimerResumed) {
      yield* _mapTimerResumedToState(event);
    } else if (event is TimerReset) {
      yield* _mapTimerResetToState(event);
    } else if (event is TimerTicked) {
      yield* _mapTimerTickedToState(event);
    }
  }

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }

  Stream<TimerState> _mapTimerStartedToState(TimerStarted start) async* {
    yield TimerRunInProgress(start.duration);
    _tickerSubscription?.cancel();
    _tickerSubscription = _ticker
        .tick(ticks: start.duration)
        .listen((duration) => add(TimerTicked(duration: duration)));
  }

  Stream<TimerState> _mapTimerPausedToState(TimerPaused pause) async* {
    if (state is TimerRunInProgress) {
      _tickerSubscription?.pause();
      yield TimerRunPause(state.duration);
    }
  }

  Stream<TimerState> _mapTimerResumedToState(TimerResumed resume) async* {
    if (state is TimerRunPause) {
      _tickerSubscription?.resume();
      yield TimerRunInProgress(state.duration);
    }
  }

  Stream<TimerState> _mapTimerResetToState(TimerReset reset) async* {
    _tickerSubscription?.cancel();
    yield TimerInitial(_duration);
  }

  Stream<TimerState> _mapTimerTickedToState(TimerTicked tick) async* {
    yield tick.duration > 0
        ? TimerRunInProgress(tick.duration)
        : TimerRunComplete();
  }
}
