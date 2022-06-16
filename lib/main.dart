import 'package:clipboard_client/page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:logger/logger.dart';
import 'package:oktoast/oktoast.dart';
import 'package:window_manager/window_manager.dart';

final logger = Logger();

void main() async {
  // 必须加上这一行。
  WidgetsFlutterBinding.ensureInitialized();
  // 必须加上这一行。
  await windowManager.ensureInitialized();
  // 对于热重载，`unregisterAll()` 需要被调用。
  await hotKeyManager.unregisterAll();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: GetMaterialApp(
        title: '剪贴板记录',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HomePage(),
      ),
    );
  }
}
