import 'package:clipboard_client/main.dart';
import 'package:clipboard_client/page/window_listener.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:clipboard/clipboard.dart';
import 'package:oktoast/oktoast.dart';
import 'package:window_manager/window_manager.dart';
import 'package:keypress_simulator/keypress_simulator.dart';

class HomePage extends StatelessWidget {
  final logic = Get.put(HomeLogic());

  HomePage({Key? key}) : super(key: key);

  final tabs = ['全部', '收藏'];

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
                            },
                            child: Container(
                              width: double.infinity,
                              height: 44,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              child: Text('${index + 1}、$e'),
                            ),
                          ),
                        );
                      });
                })
          ]),
        ));
  }

  void _init() async {
    // 添加此行以覆盖默认关闭处理程序
    await windowManager.setPreventClose(true);
    windowManager.addListener(MyWindowListener());
  }
}

class HomeLogic extends GetxController with ClipboardListener {
  final List<String> list = [];
  final List<String> collectList = [];
  bool _ignoreReSort = false;
  final tabs = ['全部', '收藏'];

  @override
  void onInit() async {
    super.onInit();
    var accessAllowed = await keyPressSimulator.isAccessAllowed();
    logger.w(accessAllowed);
    if (!accessAllowed) {
      keyPressSimulator.requestAccess(onlyOpenPrefPane: true);
    }
    // ⌥ + Q
    final HotKey hotKey = HotKey(
      KeyCode.escape,
      modifiers: [KeyModifier.control],
      // 设置热键范围（默认为 HotKeyScope.system）
      scope: HotKeyScope.system, // 设置为应用范围的热键。
    );
    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) {
        logger.wtf('onKeyDown+${hotKey.toJson()}');
      },
      // 只在 macOS 上工作。
      keyUpHandler: (hotKey) async {
        logger.wtf('onKeyUp+${hotKey.toJson()}');
        if (await windowManager.isVisible()) {
          windowManager.hide();
        } else {
          windowManager.show();
        }
      },
    );

    var keyList = [
      HotKey(
        KeyCode.digit1,
        modifiers: [KeyModifier.control],
        // 设置热键范围（默认为 HotKeyScope.system）
        scope: HotKeyScope.system, // 设置为应用范围的热键。
      ),
      HotKey(
        KeyCode.digit2,
        modifiers: [KeyModifier.control],
        // 设置热键范围（默认为 HotKeyScope.system）
        scope: HotKeyScope.system, // 设置为应用范围的热键。
      ),
      HotKey(
        KeyCode.digit3,
        modifiers: [KeyModifier.control],
        // 设置热键范围（默认为 HotKeyScope.system）
        scope: HotKeyScope.system, // 设置为应用范围的热键。
      ),
    ];
    for (int i = 0; i < keyList.length; i++) {
      hotKeyManager.register(
        keyList[i],
        keyDownHandler: (hotKey) {},
        // 只在 macOS 上工作。
        keyUpHandler: (hotKey) async {
          _ignoreReSort = true;
          await FlutterClipboard.controlC(list[i]);
          paste();
        },
      );
    }
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
  }

  @override
  void onClose() async {
    await hotKeyManager.unregisterAll();
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
    super.onClose();
  }

  @override
  void onClipboardChanged() async {
    ClipboardData? newClipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    var message = newClipboardData?.text?.trim() ?? "";
    if (message != '') {
      var indexOf = list.indexOf(message);
      if (indexOf == -1) {
        list.insert(0, message);
      } else if (indexOf == 0) {
        return;
      } else {
        if (_ignoreReSort) {
          return;
        }
        _ignoreReSort = false;
        list.removeAt(indexOf);
        list.insert(0, message);
      }
      update([tabs[0]]);
    }
  }

  void paste() async {
    // 1. Simulate pressing ⌘ + C
// 1.1 Simulate key down
    await keyPressSimulator.simulateKeyPress(
      key: LogicalKeyboardKey.keyV,
      modifiers: [ModifierKey.controlModifier],
    );
// 1.2 Simulate key up
    await keyPressSimulator.simulateKeyPress(
      key: LogicalKeyboardKey.keyV,
      modifiers: [ModifierKey.controlModifier],
      keyDown: false,
    );
  }

  void addCollect(String e) {
    if (!collectList.contains(e)) {
      collectList.add(e);
      update([tabs[1]]);
      showToast('收藏成功');
    } else {
      showToast('已存在于收藏了！');
    }
  }
}
