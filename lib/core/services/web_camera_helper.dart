import 'web_camera_helper_stub.dart'
    if (dart.library.js) 'web_camera_helper_web.dart' as impl;
import 'package:flutter/material.dart';

Future<String?> captureWebImage(BuildContext context) {
  return impl.captureWebImage(context);
}
