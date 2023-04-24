/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:ffi';

import 'initializer_isolate.dart';
import 'initializer_native_event_loop.dart';

import 'package:media_kit/generated/libmpv/bindings.dart';

/// Creates & returns initialized [Pointer] to [mpv_handle].
/// Pass [path] to libmpv dynamic library & [callback] to receive event callbacks as [Pointer] to [mpv_event].
///
/// Optionally, [options] may be passed to set libmpv options before the initialization.
///
/// Platform specific threaded event loop is preferred over [Isolate] based event loop (automatic fallback).
/// See package:media_kit_native_event_loop for more details.
///
Future<Pointer<mpv_handle>> create(
  String path,
  Future<void> Function(Pointer<mpv_event> event)? callback, {
  Map<String, String> options = const {},
}) async {
  try {
    return await InitializerNativeEventLoop.create(
      path,
      callback,
      options,
    );
  } catch (_) {
    return await InitializerIsolate.create(
      path,
      callback,
      options,
    );
  }
}
