import 'package:fish_battle/fish_battle_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(FishBattleApp());

class FishBattleApp extends StatelessWidget {
  const FishBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    return MaterialApp(debugShowCheckedModeBanner: false, home: FishBattleGame());
  }
}
