import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:media_kit/ffi/ffi.dart';

import 'common.dart';


const _kFFToolsMessageTypeReturnCode = 0;
const _kFFToolsMessageTypeLog = 1;
const _kFFToolsMessageTypeStatistics = 2;

class FFToolsMessage extends Struct {
  @Int32()
  external int type;
  external FFToolsMessageUnion data;
}

class FFToolsMessageUnion extends Union {
  @Int32()
  external int returnCode;
  external FFToolsMessageLog log;
  external FFToolsMessageStatistics statistics;
}

class FFToolsMessageLog extends Struct {
  @Int32()
  external int level;
  external Pointer<Utf8> message;
}

class FFToolsMessageStatistics extends Struct {
  @Int32()
  external int frameNumber;
  @Float()
  external double fps;
  @Float()
  external double quality;
  @Int64()
  external int size;
  @Int32()
  external int time;
  @Double()
  external double bitrate;
  @Double()
  external double speed;
}

typedef _FFToolsFFIEntryPointC = Void Function(Int64, Int, Pointer<Pointer<Utf8>>);
typedef _FFToolsFFIEntryPointDart = void Function(int, int, Pointer<Pointer<Utf8>>);

class _FFToolsLibrary implements FFToolsProvider {
	late final _FFToolsFFIEntryPointDart ffmpeg;
	late final _FFToolsFFIEntryPointDart ffprobe;
	late final void Function(int) cancel;
	_FFToolsLibrary(DynamicLibrary library) {
		final initialize = library.lookupFunction<Void Function(Pointer), void Function(Pointer)>('FFToolsFFIInitialize');
		initialize(NativeApi.postCObject);
		ffmpeg = library.lookupFunction<_FFToolsFFIEntryPointC, _FFToolsFFIEntryPointDart>('FFToolsFFIExecuteFFmpeg');
		ffprobe = library.lookupFunction<_FFToolsFFIEntryPointC, _FFToolsFFIEntryPointDart>('FFToolsFFIExecuteFFprobe');
		cancel = library.lookupFunction<Void Function(Int64), void Function(int)>('FFToolsCancel');
	}

	@override
	CancelableOperation<int> executeWithLogCallback({
		required FFTool tool,
		required List<String> arguments,
		required FFMpegLogCallback logCallback,
		FFMpegStatisticsCallback? statisticsCallback
	}) {
		final port = ReceivePort();
		final completer = CancelableCompleter<int>(
			onCancel: () {
				cancel(port.sendPort.nativePort);
			}
		);
		// Not freeing this memory is intentional. FFToolsFFI will free it when done execution.
		final argv = malloc<Pointer<Utf8>>(arguments.length);
		for (int i = 0; i < arguments.length; i++) {
			argv[i] = arguments[i].toNativeUtf8(allocator: malloc);
		}
		port.listen((data) {
			if (data is int) {
				final messagePointer = Pointer<FFToolsMessage>.fromAddress(data);
				switch (messagePointer.ref.type) {
					case _kFFToolsMessageTypeReturnCode:
						port.close();
						completer.complete(messagePointer.ref.data.returnCode);
						break;
					case _kFFToolsMessageTypeLog:
						logCallback(messagePointer.ref.data.log.level, messagePointer.ref.data.log.message.toDartString());
						break;
					case _kFFToolsMessageTypeStatistics:
						final stats = messagePointer.ref.data.statistics;
						statisticsCallback?.call(FFMpegStatisticsPacket(
							frameNumber: stats.frameNumber,
							fps: stats.fps,
							quality: stats.quality,
							size: stats.size,
							time: stats.time,
							bitrate: stats.bitrate,
							speed: stats.speed
						));
				}
				if (messagePointer.ref.type == _kFFToolsMessageTypeLog) {
					malloc.free(messagePointer.ref.data.log.message);
				}
				malloc.free(messagePointer);
			}
		});
		if (tool == FFTool.ffmpeg) {
			ffmpeg(port.sendPort.nativePort, arguments.length, argv);
		}
		else {
			ffprobe(port.sendPort.nativePort, arguments.length, argv);
		}
		return completer.operation;
	}
}

extension _IsExecutable on FileStat {
	bool get isExecutable {
		final permissions = mode & 0xFFF;
		final userPermissions = (permissions >> 6) & 0x7;
		return userPermissions & 0x1 == 1;
	}
}

class _FFToolsCLI implements FFToolsProvider {
	final String ffmpeg;
	final String ffprobe;

	const _FFToolsCLI({
		required this.ffmpeg,
		required this.ffprobe
	});

	@override
	CancelableOperation<int> executeWithLogCallback({
		required FFTool tool,
		required List<String> arguments,
		required FFMpegLogCallback logCallback,
		FFMpegStatisticsCallback? statisticsCallback
	}) {
		Process? process;
		final completer = CancelableCompleter<int>(
			onCancel: () {
				process?.kill();
			}
		);
		Process.start(
			tool == FFTool.ffmpeg ? ffmpeg : ffprobe,
			arguments,
		).then((p) {
			process = p;
			p.stdout.transform(utf8.decoder).forEach((s) {
				logCallback(32, s);
			});
			p.stderr.transform(utf8.decoder).forEach((s) {
				logCallback(-16, s);
			});
			completer.complete(p.exitCode);
		});
		return completer.operation;
	}
}

class _FFToolsMissing implements FFToolsProvider {
	const _FFToolsMissing();
	@override
	CancelableOperation<int> executeWithLogCallback({
		required FFTool tool,
		required List<String> arguments,
		required FFMpegLogCallback logCallback,
		FFMpegStatisticsCallback? statisticsCallback
	}) {
		throw Exception('FFTools could not be found');
	}
}

FFToolsProvider resolveFFTools() {
	// Attempt to load [LIBMPV_LIBRARY_PATH] environment variable.
	try {
		final env = Platform.environment['FFTOOLSFFI_LIBRARY_PATH'];
		if (env != null) {
			return _FFToolsLibrary(DynamicLibrary.open(env));
		}
	} catch (_) {}
	// Attempt to load default names
	final names = {
		'macos': [
			'Fftools-ffi.framework/Fftools-ffi',
		],
		'ios': [
			'Fftools-ffi.framework/Fftools-ffi',
		],
		'android': [
			// Statically-linked within libmpv
			'libmpv.so',
		],
		'windows': [
			// Statically-linked within libmpv
			'libmpv-2.dll'
		]
	}[Platform.operatingSystem];
	for (final name in names ?? const Iterable.empty()) {
		try {
			return _FFToolsLibrary(DynamicLibrary.open(name));
		}
		catch (_) {}
	}
	final paths = Platform.environment['PATH']?.split(Platform.isWindows ? ';' : ':') ?? [];
	for (final path in paths) {
		if (path.isEmpty) {
			continue;
		}
		final ffmpegPath = '$path/ffmpeg';
		final ffmpeg = File(ffmpegPath).statSync();
		final ffprobePath = '$path/ffprobe';
		final ffprobe = File(ffprobePath).statSync();
		if (ffmpeg.type != FileSystemEntityType.notFound && ffmpeg.isExecutable && ffprobe.type != FileSystemEntityType.notFound && ffprobe.isExecutable) {
			return _FFToolsCLI(
				ffmpeg: ffmpegPath,
				ffprobe: ffprobePath
			);
		}
	}

	return const _FFToolsMissing();
}
