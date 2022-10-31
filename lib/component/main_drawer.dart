import 'package:flutter/material.dart';

import '../const/regions.dart';

typedef OnRegionTap = void Function(String region);

class MainDrawer extends StatelessWidget {
  final OnRegionTap onRegionTap;
  final String selectedRegion;
  final Color darkColor;
  final Color lightColor;

  const MainDrawer({
    required this.onRegionTap,
    required this.selectedRegion,
    required this.darkColor,
    required this.lightColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: darkColor,
      child: ListView(
        children: [
          DrawerHeader(
            child: Text(
              '지역 선택',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
          ),
          ...regions
              .map(
                (e) => ListTile(
                  // List 형태가 아닌 하나씩 들어가게 하기 위해 '...' 사용
                  tileColor: Colors.white,
                  selectedTileColor: lightColor,
                  selectedColor: Colors.black,
                  selected: e == selectedRegion, // 선택된 상태
                  onTap: () {
                    onRegionTap(e);
                  },
                  title: Text(e),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}
