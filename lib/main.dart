import 'package:dusty_dust/model/stat_model.dart';
import 'package:dusty_dust/screen/home_screen.dart';
import 'package:dusty_dust/screen/test_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

const testBox = 'test';
void main() async {
  await Hive.initFlutter();

  // 어댑터 등록
  Hive.registerAdapter<StatModel>(StatModelAdapter());
  Hive.registerAdapter<ItemCode>(ItemCodeAdapter());

  await Hive.openBox(testBox);

  // itemCode 내 아이템들을 title로 box를 연다.
  for(ItemCode itemCode in ItemCode.values) {
    // Generic을 넣어서 상세하게 정의를 해줄 수도 있다.
    await Hive.openBox<StatModel>(itemCode.name);
  }

  runApp(
    MaterialApp(
      theme: ThemeData(
        fontFamily: 'sunflower',
      ),
      home: HomeScreen(),
    ),
  );
}