String formatMillis(int ms) {
  final minutes = (ms ~/ 60000);
  final seconds = ((ms % 60000) ~/ 1000);
  final millis  = (ms % 1000);
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  final S  = millis.toString().padLeft(3, '0');
  return '$mm:$ss.$S';
}
