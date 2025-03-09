import 'package:fish_battle/fish.dart';
import 'package:flutter/material.dart';

class FishWidget extends StatelessWidget {
  final Fish fish;

  const FishWidget(this.fish, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: FishPainter(fish));
  }
}

class FishPainter extends CustomPainter {
  final Fish fish;

  FishPainter(this.fish);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    if (fish.isPlayer) {
      paint.color = Colors.red; // 玩家鱼为红色
    } else if (fish is FoodFish) {
      paint.color = Colors.green; // -1 级食物鱼为绿色
    } else {
      paint.color = Colors.blue; // 普通 AI 鱼为蓝色
    }
    double radius = fish.level >= 0 ? 10 + fish.level * 5 : 5;
    canvas.drawCircle(const Offset(0, 0), radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
