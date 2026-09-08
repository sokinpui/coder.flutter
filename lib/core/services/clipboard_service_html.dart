// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

import 'clipboard_service.dart';

ClipboardService createClipboardService() => HtmlClipboardService();

class HtmlClipboardService implements ClipboardService {
  HtmlClipboardService() {
    html.document.onPaste.listen(_handleHtmlPaste);
  }

  Uint8List? _lastPastedImage;
  final StreamController<Uint8List> _imageStreamController =
      StreamController<Uint8List>.broadcast();

  @override
  Stream<Uint8List> get onImagePasted => _imageStreamController.stream;

  void _handleHtmlPaste(html.ClipboardEvent event) {
    final items = event.clipboardData?.items;
    if (items == null) return;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.type != null && item.type!.startsWith('image/')) {
        final blob = item.getAsFile();
        if (blob == null) continue;

        final reader = html.FileReader();
        reader.onLoadEnd.listen((_) {
          final result = reader.result;
          if (result is Uint8List) {
            _lastPastedImage = result;
            _imageStreamController.add(result);
          } else if (result is String) {
            final comma = result.indexOf(',');
            if (comma != -1) {
              final bytes = base64Decode(result.substring(comma + 1));
              _lastPastedImage = bytes;
              _imageStreamController.add(bytes);
            }
          }
        });
        reader.readAsArrayBuffer(blob);
        event.preventDefault();
        break;
      }
    }
  }

  @override
  Future<Uint8List?> getClipboardImage() async {
    final img = _lastPastedImage;
    _lastPastedImage = null;
    return img;
  }

  @override
  Future<Uint8List?> pickImage() async {
    final completer = Completer<Uint8List?>();
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final reader = html.FileReader();
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        if (result is Uint8List) {
          completer.complete(result);
        } else {
          completer.complete(null);
        }
      });
      reader.readAsArrayBuffer(files[0]);
    });

    return completer.future;
  }
}
