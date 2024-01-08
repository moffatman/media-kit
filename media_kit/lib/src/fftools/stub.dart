import 'package:async/async.dart';

import 'common.dart';

class _FFToolsUnsupported implements FFToolsProvider {
	const _FFToolsUnsupported();
	@override
	CancelableOperation<int> executeWithLogCallback({
		required FFTool tool,
		required List<String> arguments,
		required FFMpegLogCallback logCallback,
		FFMpegStatisticsCallback? statisticsCallback
	}) {
		throw UnimplementedError('FFTools is not supported on this platform');
	}
}

FFToolsProvider resolveFFTools() => const _FFToolsUnsupported();
