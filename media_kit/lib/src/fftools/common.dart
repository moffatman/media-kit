import 'package:async/async.dart';

class FFMpegStatisticsPacket {
	final int frameNumber;
	final double fps;
	final double quality;
	final int size;
	final int time;
	final double bitrate;
	final double speed;

	const FFMpegStatisticsPacket({
		required this.frameNumber,
		required this.fps,
		required this.quality,
		required this.size,
		required this.time,
		required this.bitrate,
		required this.speed
	});

	@override
	String toString() => 'FFMpegStatisticsPacket(frameNumber: $frameNumber, fps: $fps, quality: $quality, size: $size, time: $time, bitrate: $bitrate, speed: $speed)';
}

typedef FFMpegLogCallback = void Function(int, String);
typedef FFMpegStatisticsCallback = void Function(FFMpegStatisticsPacket packet);

enum FFTool {
	ffmpeg,
	ffprobe
}

abstract class FFToolsProvider {
	CancelableOperation<int> executeWithLogCallback({
		required FFTool tool,
		required List<String> arguments,
		required FFMpegLogCallback logCallback,
		FFMpegStatisticsCallback? statisticsCallback
	});
}
