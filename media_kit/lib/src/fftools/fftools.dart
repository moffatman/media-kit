import 'package:async/async.dart';

import 'common.dart';
export 'common.dart' show FFMpegStatisticsPacket, FFMpegLogCallback, FFMpegStatisticsCallback;
import 'vm.dart' if (dart.library.html) 'stub.dart';

class FFToolsOutput {
	final int returnCode;
	final String output;

	const FFToolsOutput({
		required this.returnCode,
		required this.output
	});

	@override
	String toString() => 'FFToolsOutput(returnCode: $returnCode, output length: ${output.length})';
}

class FFTools {
	static FFToolsProvider? _fftools;

	static CancelableOperation<int> ffmpegWithLogCallback({
		required List<String> arguments,
		required FFMpegLogCallback logCallback,
		FFMpegStatisticsCallback? statisticsCallback
	}) {
		return (_fftools ??= resolveFFTools()).executeWithLogCallback(
			tool: FFTool.ffmpeg,
			arguments: arguments,
			logCallback: logCallback,
			statisticsCallback: statisticsCallback
		);
	}

	static CancelableOperation<FFToolsOutput> _collectOutput({
		required FFTool tool,
		required List<String> arguments,
		required int logLevel,
		FFMpegStatisticsCallback? statisticsCallback
	}) {
		final buffer = StringBuffer();
		final returnCodeOperation = (_fftools ??= resolveFFTools()).executeWithLogCallback(
			tool: tool,
			arguments: arguments,
			logCallback: (level, message) {
				if (level <= logLevel) {
					buffer.write(message);
				}
			},
			statisticsCallback: statisticsCallback
		);
		return returnCodeOperation.then(
			(returnCode) {
				return FFToolsOutput(
					returnCode: returnCode,
					output: buffer.toString()
				);
			}
		);
	}

	static CancelableOperation<FFToolsOutput> ffmpeg({
		required List<String> arguments,
		int logLevel = 32,
		FFMpegStatisticsCallback? statisticsCallback
	}) => _collectOutput(
		tool: FFTool.ffmpeg,
		arguments: arguments,
		logLevel: logLevel,
		statisticsCallback: statisticsCallback
	);

	static Future<FFToolsOutput> ffprobe({
		required List<String> arguments,
		int logLevel = 32
	}) => _collectOutput(
		tool: FFTool.ffprobe,
		arguments: arguments,
		logLevel: logLevel
	).value;
}
