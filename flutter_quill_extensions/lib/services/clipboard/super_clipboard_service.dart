import 'dart:async' show Completer;

import 'package:flutter/foundation.dart';
// ignore: implementation_imports
import 'package:flutter_quill/src/services/clipboard/clipboard_service.dart';
import 'package:super_clipboard/super_clipboard.dart';

/// Implementation based on https://pub.dev/packages/super_clipboard
class SuperClipboardService implements ClipboardService {
  /// Null if the Clipboard API is not supported on this platform
  /// https://pub.dev/packages/super_clipboard#usage
  SystemClipboard? _getSuperClipboard() {
    return SystemClipboard.instance;
  }

  Future<bool> _canProvide({required DataFormat format}) async {
    final clipboard = _getSuperClipboard();
    if (clipboard == null) {
      return false;
    }
    final reader = await clipboard.read();
    return reader.canProvide(format);
  }

  Future<Uint8List> _provideFileAsBytes({required FileFormat format}) async {
    final clipboard = _getSuperClipboard();
    if (clipboard == null) {
      // To avoid getting this exception, use _canProvide()
      throw UnsupportedError(
        'Clipboard API is not supported on this platform.',
      );
    }
    final reader = await clipboard.read();
    final completer = Completer<Uint8List>();

    reader.getFile(format, (file) async {
      final bytes = await file.readAll();
      completer.complete(bytes);
    });
    final bytes = await completer.future;
    return bytes;
  }

  /// According to super_clipboard docs, will return `null` if the value
  /// is not available or the data is virtual (macOS and Windows)
  Future<String?> _provideSimpleValueFormatAsString({
    required SimpleValueFormat<String> format,
  }) async {
    final clipboard = _getSuperClipboard();
    if (clipboard == null) {
      // To avoid getting this exception, use _canProvide()
      throw UnsupportedError(
        'Clipboard API is not supported on this platform.',
      );
    }
    final reader = await clipboard.read();
    final value = await reader.readValue<String>(format);
    return value;
  }

  /// This will need to be updated if [getImageFileAsBytes] updated.
  /// Notice that even if the copied image is JPEG, it still can be provided
  /// as PNG, will handle JPEG check in case this info is incorrect.
  @override
  Future<bool> canProvideImageFile() async {
    final canProvidePngFile = await _canProvide(format: Formats.png);
    if (canProvidePngFile) {
      return true;
    }
    final canProvideJpegFile = await _canProvide(format: Formats.jpeg);
    if (canProvideJpegFile) {
      return true;
    }
    return false;
  }

  /// This will need to be updated if [canProvideImageFile] updated.
  @override
  Future<Uint8List> getImageFileAsBytes() async {
    final canProvidePngFile = await _canProvide(format: Formats.png);
    if (canProvidePngFile) {
      return _provideFileAsBytes(format: Formats.png);
    }
    return _provideFileAsBytes(format: Formats.jpeg);
  }

  @override
  Future<bool> canProvidePlainText() {
    return _canProvide(format: Formats.plainText);
  }

  @override
  Future<String?> getPlainText() {
    return _provideSimpleValueFormatAsString(format: Formats.plainText);
  }

  @override
  Future<bool> canProvideHtmlText() {
    return _canProvide(format: Formats.htmlText);
  }

  @override
  Future<String?> getHtmlText() {
    return _provideSimpleValueFormatAsString(format: Formats.htmlText);
  }

  @override
  Future<bool> canProvideGifFile() {
    return _canProvide(format: Formats.gif);
  }

  @override
  Future<Uint8List> getGifFileAsBytes() {
    return _provideFileAsBytes(format: Formats.gif);
  }

  @override
  Future<bool> canPaste() async {
    final clipboard = _getSuperClipboard();
    if (clipboard == null) {
      return false;
    }
    final reader = await clipboard.read();
    final availablePlatformFormats = reader.platformFormats;
    return availablePlatformFormats.isNotEmpty;
  }
}