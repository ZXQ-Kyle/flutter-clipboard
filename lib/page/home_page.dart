import 'package:clipboard_client/main.dart';
import 'package:clipboard_client/page/window_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:clipboard/clipboard.dart';
import 'package:oktoast/oktoast.dart';
import 'package:window_manager/window_manager.dart';
import 'home_logic.dart';

class HomePage extends StatelessWidget {
  final logic = Get.put(HomeLogic());

  HomePage({Key? key}) : super(key: key);

  final tabs = ['全部', '收藏'];

  void _init() async {
    // 添加此行以覆盖默认关闭处理程序
    await windowManager.setPreventClose(true);
    windowManager.addListener(MyWindowListener());
  }

  @override
  Widget build(BuildContext context) {
    _init();
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: SizedBox(
              width: 160,
              child: TabBar(
                tabs: tabs.map((e) => Tab(text: e)).toList(growable: false),
              ),
            ),
            actions: [
              Container(
                width: 220,
                height: 40,
                padding: const EdgeInsets.only(left: 16, right: 4),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: TextField(
                  controller: logic.controller,
                  decoration: InputDecoration(
                    hintText: "搜索文本",
                    suffixIcon: InkWell(
                      onTap: () {
                        logic.clear();
                      },
                      child: Icon(Icons.clear),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          body: TabBarView(children: [
            GetBuilder<HomeLogic>(
                id: tabs[0],
                builder: (controller) {
                  return ListView.builder(
                      itemCount: logic.list.length,
                      itemBuilder: (ctx, index) {
                        var e = logic.list[index];
                        return Ink(
                          color: index % 2 == 0 ? Colors.white : Colors.grey[200],
                          child: InkWell(
                            onTap: () {
                              FlutterClipboard.controlC(e);
                              showToast('已复制');
                              windowManager.hide();
                            },
                            child: Container(
                              width: double.infinity,
                              height: 44,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(child: Text('${index + 1}、$e')),
                                  InkWell(
                                    onTap: () {
                                      logic.addCollect(e);
                                    },
                                    child: const SizedBox(
                                      height: double.infinity,
                                      width: 60,
                                      child: Icon(Icons.star, size: 30, color: Color(0xffffd858)),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      });
                }),
            GetBuilder<HomeLogic>(
                id: tabs[1],
                builder: (controller) {
                  return ListView.builder(
                      itemCount: logic.collectList.length,
                      itemBuilder: (ctx, index) {
                        var e = logic.collectList[index];
                        return Ink(
                          color: index % 2 == 0 ? Colors.white : Colors.grey[200],
                          child: InkWell(
                            onTap: () {
                              FlutterClipboard.controlC(e);
                              showToast('已复制');
                              windowManager.hide();
                              logic.paste();
                            },
                            child: Container(
                              width: double.infinity,
                              height: 44,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(child: Text('${index + 1}、$e')),
                                  InkWell(
                                    onTap: () {
                                      logic.removeCollect(e);
                                    },
                                    child: const SizedBox(
                                      height: double.infinity,
                                      width: 60,
                                      child: Icon(Icons.delete_forever_outlined, size: 24, color: Colors.red),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      });
                })
          ]),
        ));
  }
}
