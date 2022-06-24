import 'package:clipboard/clipboard.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:keypress_simulator/keypress_simulator.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:flutter/services.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:clipboard_client/main.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:window_manager/window_manager.dart';

const dbKeyAll = 'all';
const dbKeyCollect = 'collect';

class HomeLogic extends GetxController with ClipboardListener {
  late List<String> totalList;
  late List<String> list;
  late List<String> collectList;
  bool _ignoreReSort = false;
  final tabs = ['全部', '收藏'];
  late Box<dynamic> box;

  var controller = TextEditingController();

  @override
  void onInit() async {
    super.onInit();
    // RawKeyboard.instance.addListener((rawKeyEvent) {
    //   logger.wtf(rawKeyEvent);
    // });

    box = Hive.box(hiveBoxApp);
    list = box.get(dbKeyAll, defaultValue: <String>[]);
    totalList = list;
    collectList = box.get(dbKeyCollect, defaultValue: <String>[]);

    var accessAllowed = await keyPressSimulator.isAccessAllowed();
    logger.w(accessAllowed);
    if (!accessAllowed) {
      keyPressSimulator.requestAccess(onlyOpenPrefPane: true);
    }
    // ⌥ + Q
    final HotKey hotKey = HotKey(
      KeyCode.backquote,
      modifiers: [KeyModifier.control],
      // 设置热键范围（默认为 HotKeyScope.system）
      scope: HotKeyScope.system, // 设置为应用范围的热键。
    );
    hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) async {
        if (await windowManager.isFocused()) {
          windowManager.hide();
        } else {
          windowManager.show();
        }
      },
      // 只在 macOS 上工作。
      keyUpHandler: (hotKey) async {},
    );
    final HotKey hotKeyEnter = HotKey(
      KeyCode.enter,
      modifiers: [],
      // 设置热键范围（默认为 HotKeyScope.system）
      scope: HotKeyScope.inapp, // 设置为应用范围的热键。
    );
    hotKeyManager.register(
      hotKeyEnter,
      keyDownHandler: (hotKey) {
        search();
      },
    );
    final HotKey hotKeyEsc = HotKey(
      KeyCode.escape,
      modifiers: [],
      // 设置热键范围（默认为 HotKeyScope.system）
      scope: HotKeyScope.inapp, // 设置为应用范围的热键。
    );
    hotKeyManager.register(
      hotKeyEsc,
      keyDownHandler: (hotKey) {
        clear();
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
        keyDownHandler: (hotKey) async {
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
      var indexOf = totalList.indexOf(message);
      if (indexOf == -1) {
        totalList.insert(0, message);
      } else if (indexOf == 0) {
        return;
      } else {
        if (_ignoreReSort) {
          return;
        }
        _ignoreReSort = false;
        totalList.removeAt(indexOf);
        totalList.insert(0, message);
      }
      update([tabs[0]]);
      box.put(dbKeyAll, totalList);
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
      box.put(dbKeyCollect, collectList);
    } else {
      showToast('已存在于收藏了！');
    }
  }

  void removeCollect(String e) {
    collectList.remove(e);
    update([tabs[1]]);
    showToast('移除成功');
    box.put(dbKeyCollect, collectList);
  }

  void search() {
    var text = controller.text;
    if (text == '') {
      return;
    }
    list = totalList.where((element) {
      return element.contains(text);
    }).toList();
    update([tabs[0]]);
  }

  void clear() {
    controller.text = '';
    list = totalList;
    update([tabs[0]]);
  }
}
