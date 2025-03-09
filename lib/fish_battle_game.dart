import 'dart:async';
import 'dart:math';

import 'package:fish_battle/fish.dart';
import 'package:fish_battle/widget/fish_widget.dart';
import 'package:flutter/material.dart';

class FishBattleGame extends StatefulWidget {
  const FishBattleGame({super.key});

  @override
  State<StatefulWidget> createState() => _FishBattleGameState();
}

class _FishBattleGameState extends State<FishBattleGame> {
  List<Fish> fishes = [];
  late Fish playerFish;
  Timer? gameTimer;
  Size mapSize = const Size(5000, 5000);
  Random random = Random();
  Offset cameraOffset = Offset.zero;
  Offset? joystickOffset; // 摇杆偏移量
  Offset joystickCenter = const Offset(100, 400); // 摇杆中心位置

  @override
  void initState() {
    super.initState();
    // 初始化玩家鱼，位于地图中心
    playerFish = Fish(position: Offset(100, 100), isPlayer: true);
    fishes.add(playerFish);
    spawnInitialFishes();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });
  }

  void spawnInitialFishes() {
    // 生成AI鱼，随机分布在地图上
    for (int i = 0; i < 5; i++) {
      fishes.add(Fish(position: Offset(random.nextDouble() * mapSize.width, random.nextDouble() * mapSize.height)));
    }
    // 生成食物鱼，随机分布但保持一定数量
    for (int i = 0; i < 20; i++) {
      fishes.add(FoodFish(position: Offset(random.nextDouble() * mapSize.width, random.nextDouble() * mapSize.height)));
    }
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    // 计算相机偏移，确保玩家鱼在屏幕中心，并限制在地图范围内
    cameraOffset = Offset((playerFish.position.dx - screenSize.width / 2).clamp(0, mapSize.width - screenSize.width), (playerFish.position.dy - screenSize.height / 2).clamp(0, mapSize.height - screenSize.height));

    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          joystickOffset = details.localPosition - joystickCenter;
        });
      },
      onPanUpdate: (details) {
        setState(() {
          joystickOffset = details.localPosition - joystickCenter;
          if (joystickOffset != null) {
            playerFish.direction = atan2(joystickOffset!.dy, joystickOffset!.dx) * 180 / pi;
          }
        });
      },
      onPanEnd: (details) {
        setState(() {
          joystickOffset = null; // 松开时停止移动
        });
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: Colors.blue[100]),
            Transform(transform: Matrix4.translationValues(-cameraOffset.dx, -cameraOffset.dy, 0), child: Stack(children: [...fishes.map((fish) => Positioned(left: fish.position.dx, top: fish.position.dy, child: FishWidget(fish)))])),
            // 调试信息
            Positioned(
              top: 10,
              left: 10,
              child: Text(
                '等级: ${playerFish.level}  吃掉的鱼: ${playerFish.eatenCount}\n'
                '玩家位置: (${playerFish.position.dx.toStringAsFixed(0)}, ${playerFish.position.dy.toStringAsFixed(0)})',
                style: const TextStyle(fontSize: 10, color: Colors.black),
              ),
            ),
            // 摇杆UI
            Positioned(left: joystickCenter.dx - 50, top: joystickCenter.dy - 50, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.withAlpha(50)), child: Center(child: Container(width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey), transform: joystickOffset != null ? Matrix4.translationValues(joystickOffset!.dx.clamp(-30, 30), joystickOffset!.dy.clamp(-30, 30), 0) : Matrix4.identity())))),
          ],
        ),
      ),
    );
  }

  void updateGame() {
    for (var fish in fishes) {
      if (fish.isPlayer && joystickOffset != null) {
        moveFish(fish); // 只有摇杆激活时玩家鱼才移动
      } else if (!fish.isPlayer) {
        updateAI(fish);
        moveFish(fish);
      }
    }
    checkCollisions();
    // 保持食物鱼数量
    if (fishes.whereType<FoodFish>().length < 20) {
      fishes.add(FoodFish(position: Offset(playerFish.position.dx + random.nextDouble() * 1000 - 500, playerFish.position.dy + random.nextDouble() * 1000 - 500)));
    }
    setState(() {});
  }

  void moveFish(Fish fish) {
    double dx = fish.speed * cos(fish.direction * pi / 180) * 0.016;
    double dy = fish.speed * sin(fish.direction * pi / 180) * 0.016;
    fish.position = Offset((fish.position.dx + dx).clamp(0, mapSize.width), (fish.position.dy + dy).clamp(0, mapSize.height));
  }

  void updateAI(Fish fish) {
    Fish? target = findNearestSmallerFish(fish);
    Fish? threat = findNearestLargerFish(fish);
    if (threat != null) {
      fish.direction = directionAwayFrom(threat.position, fish.position);
    } else if (target != null) {
      fish.direction = directionTo(target.position, fish.position);
    } else {
      fish.direction += random.nextDouble() * 10 - 5;
    }
  }

  Fish? findNearestSmallerFish(Fish fish) {
    Fish? nearest;
    double minDistance = double.infinity;
    for (var other in fishes) {
      if (other.level < fish.level && other != fish) {
        double distance = (other.position - fish.position).distance;
        if (distance < minDistance) {
          minDistance = distance;
          nearest = other;
        }
      }
    }
    return nearest;
  }

  Fish? findNearestLargerFish(Fish fish) {
    Fish? nearest;
    double minDistance = double.infinity;
    for (var other in fishes) {
      if (other.level > fish.level && other != fish) {
        double distance = (other.position - fish.position).distance;
        if (distance < minDistance) {
          minDistance = distance;
          nearest = other;
        }
      }
    }
    return nearest;
  }

  double directionTo(Offset target, Offset from) {
    double dx = target.dx - from.dx;
    double dy = target.dy - from.dy;
    return atan2(dy, dx) * 180 / pi;
  }

  double directionAwayFrom(Offset threat, Offset from) {
    double dx = from.dx - threat.dx;
    double dy = from.dy - threat.dy;
    return atan2(dy, dx) * 180 / pi;
  }

  void checkCollisions() {
    for (int i = 0; i < fishes.length; i++) {
      for (int j = i + 1; j < fishes.length; j++) {
        Fish a = fishes[i];
        Fish b = fishes[j];
        if (isColliding(a, b)) {
          if (a.level > b.level) {
            a.eatenCount++;
            if (a.eatenCount % 10 == 0) {
              a.level++;
              a.speed = 50 + a.level * 10;
            }
            fishes.remove(b);
          } else if (b.level > a.level) {
            b.eatenCount++;
            if (b.eatenCount % 10 == 0) {
              b.level++;
              b.speed = 50 + b.level * 10;
            }
            fishes.remove(a);
          }
        }
      }
    }
    if (!fishes.contains(playerFish)) {
      endGame();
    }
  }

  bool isColliding(Fish a, Fish b) {
    double distance = (a.position - b.position).distance;
    return distance < (10 + a.level * 5) + (10 + b.level * 5);
  }

  void endGame() {
    gameTimer?.cancel();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('游戏结束'),
            content: Text('你的最终等级: ${playerFish.level}，吃掉的鱼: ${playerFish.eatenCount}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  restartGame();
                },
                child: const Text('重玩'),
              ),
            ],
          ),
    );
  }

  void restartGame() {
    setState(() {
      fishes.clear();
      playerFish = Fish(position: const Offset(2500, 2500), isPlayer: true);
      fishes.add(playerFish);
      spawnInitialFishes();
      gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        updateGame();
      });
    });
  }
}
