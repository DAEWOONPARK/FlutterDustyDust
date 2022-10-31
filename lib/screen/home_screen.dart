import 'package:dio/dio.dart';
import 'package:dusty_dust/component/main_app_bar.dart';
import 'package:dusty_dust/component/main_drawer.dart';
import 'package:dusty_dust/container/category_card.dart';
import 'package:dusty_dust/model/stat_model.dart';
import 'package:dusty_dust/repository/stat_repository.dart';
import 'package:dusty_dust/utils/data_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../const/regions.dart';
import '../container/hourly_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String region = regions[0];
  bool isExpanded = true;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(scrollListener);
    fetchData(); // TOD
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final now = DateTime.now();
      final fetchTime = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
      );
      final box = Hive.box<StatModel>(ItemCode.PM10.name);

      if (box.values.isNotEmpty &&
          (box.values.last as StatModel).dataTime.isAtSameMomentAs(fetchTime)) {
        print('이미 최신 데이터가 있습니다.');
        return;
      }

      // void로 수정
      List<Future> futures = [];
      for (ItemCode itemCode in ItemCode.values) {
        futures.add(
          StatRepository.fetchData(
            itemCode: itemCode,
          ),
        );
      }

      // 요청은 동시에 하되, 리스트 안에 Future들이 모두 끝 날때까지 기다림
      // results에는 Future 리스트에 넣은 순서대로 결과 값을 받는다.
      final results = await Future.wait(futures);

      for (int i = 0; i < results.length; i++) {
        final key = ItemCode.values[i];
        final value = results[i];

        final box = Hive.box<StatModel>(key.name);

        for (StatModel stat in value) {
          box.put(stat.dataTime.toString(), stat);
        }

        final allKeys = box.keys.toList();
        if (allKeys.length > 24) {
          final deleteKeys = allKeys.sublist(0, allKeys.length - 24);
          box.deleteAll(deleteKeys);
        }
      }
    } on DioError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('인터넷 연결이 원활하지 않습니다.'),
        ),
      );
    }
  }

  scrollListener() {
    bool isExpanded = scrollController.offset < 500 - kToolbarHeight;

    if (isExpanded != this.isExpanded) {
      setState(() {
        this.isExpanded = isExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
        valueListenable: Hive.box<StatModel>(ItemCode.PM10.name).listenable(),
        builder: (context, box, widget) {
          if(box.values.isEmpty) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final recentStat = (box.values.toList().last) as StatModel;
          final status = DataUtils.getStatusFromItemCodeAndValue(
            value: recentStat.getLevelFromRegion(region),
            itemCode: ItemCode.PM10,
          );

          return Scaffold(
              drawer: MainDrawer(
                darkColor: status.darkColor,
                lightColor: status.lightColor,
                selectedRegion: region,
                onRegionTap: (String region) {
                  setState(() {
                    this.region = region;
                  });
                  Navigator.of(context).pop();
                },
              ),
              body: Container(
                color: status.primaryColor,
                child: RefreshIndicator(
                  onRefresh: () async {
                    await fetchData();
                  },
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      MainAppBar(
                        region: region,
                        stat: recentStat,
                        status: status,
                        dateTime: recentStat.dataTime,
                        isExpanded: isExpanded,
                      ),
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CategoryCard(
                              region: region,
                              darkColor: status.darkColor,
                              lightColor: status.lightColor,
                            ),
                            const SizedBox(height: 16.0),
                            ...ItemCode.values.map((itemCode) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: HourlyCard(
                                  darkColor: status.darkColor,
                                  lightColor: status.lightColor,
                                  itemCode: itemCode,
                                  region: region,
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 16.0),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ));
        });
  }
}
