import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class MyWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    // bool _isPreventClose = await windowManager.isPreventClose();
    // if (_isPreventClose) {
    //   showDialog(
    //     context: context,
    //     builder: (_) {
    //       return AlertDialog(
    //         title: Text('Are you sure you want to close this window?'),
    //         actions: [
    //           TextButton(
    //             child: Text('No'),
    //             onPressed: () {
    //               Navigator.of(context).pop();
    //             },
    //           ),
    //           TextButton(
    //             child: Text('Yes'),
    //             onPressed: () {
    //               Navigator.of(context).pop();
    //               await windowManager.destroy();
    //             },
    //           ),
    //         ],
    //       );
    //     },
    //   );
    // }
  }
}
