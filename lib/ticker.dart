//Ticker Class does is expose a tick function which takes the number of ticks we want and returns 
// a stream which emits the remaining seconds every second

class Ticker{
  const Ticker();
  Stream<int> tick({int ticks}){
    return Stream.periodic(Duration(seconds: 1),(x)=> ticks - x - 1).take(ticks);
  }
}