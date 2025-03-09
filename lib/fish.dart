import 'dart:math';
import 'dart:ui';

class Fish {
  Offset position;
  double speed;
  double direction;
  int level;
  int eatenCount;
  bool isPlayer;

  Fish({required this.position, this.level = 0, this.isPlayer = false}) : speed = 100 + level * 10, direction = Random().nextDouble() * 360, eatenCount = 0;
}

class FoodFish extends Fish {
  FoodFish({required super.position}) : super(level: -1, isPlayer: false) {
    speed = 100;
  }
}
