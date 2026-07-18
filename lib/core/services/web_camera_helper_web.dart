import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Future<String?> captureWebImage(BuildContext context) async {
  final completer = Completer<String?>();
  
  html.MediaStream? stream;
  try {
    stream = await html.window.navigator.mediaDevices?.getUserMedia({
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      }
    });
  } catch (e) {
    completer.complete(null);
    return completer.future;
  }

  if (stream == null) {
    completer.complete(null);
    return completer.future;
  }

  final videoElement = html.VideoElement()
    ..autoplay = true
    ..srcObject = stream
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.objectFit = 'cover'
    ..style.borderRadius = '12px';

  final viewId = 'webcam_view_${DateTime.now().millisecondsSinceEpoch}';
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) => videoElement);

  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    builder: (dialogCtx) => Dialog(
      backgroundColor: const Color(0xff111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff3b82f6), Color(0xff8b5cf6)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Capture Photo',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      stream?.getTracks().forEach((track) => track.stop());
                      Navigator.pop(dialogCtx);
                      completer.complete(null);
                    },
                    icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.06),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            // Camera feed
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                clipBehavior: Clip.antiAlias,
                child: HtmlElementView(viewType: viewId),
              ),
            ),
            // Action buttons
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white54,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                      ),
                      onPressed: () {
                        stream?.getTracks().forEach((track) => track.stop());
                        Navigator.pop(dialogCtx);
                        completer.complete(null);
                      },
                      child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff3b82f6), Color(0xff2563eb)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff3b82f6).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          try {
                            final canvas = html.CanvasElement(
                              width: videoElement.videoWidth > 0 ? videoElement.videoWidth : 640,
                              height: videoElement.videoHeight > 0 ? videoElement.videoHeight : 480,
                            );
                            final ctx = canvas.context2D;
                            ctx.drawImage(videoElement, 0, 0);
                            
                            final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
                            
                            stream?.getTracks().forEach((track) => track.stop());
                            Navigator.pop(dialogCtx);
                            completer.complete(dataUrl);
                          } catch (e) {
                            stream?.getTracks().forEach((track) => track.stop());
                            Navigator.pop(dialogCtx);
                            completer.complete(null);
                          }
                        },
                        icon: const Icon(Icons.camera_rounded, size: 20),
                        label: const Text('Capture', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return completer.future;
}
