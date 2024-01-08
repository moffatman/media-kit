import 'dart:convert';

import 'package:media_kit/media_kit.dart';
import 'package:test/test.dart';

import '../../common/sources.dart';

Future<Map<String, dynamic>> _scan(String path) async {
	final result = await FFTools.ffprobe(
		arguments: [
			"-v",
				"error",
				"-hide_banner",
				"-print_format",
				"json",
				"-show_format",
				"-show_streams",
				"-show_chapters",
				"-i",
				path
		]
	);
	return jsonDecode(result.output);
}

void main() {
	// TODO: Skip on web? Can  dart test even be run on web?
	setUp(() async {
    MediaKit.ensureInitialized();

    await sources.prepare();

    // For preventing video driver & audio driver initialization errors in unit-tests.
    NativePlayer.test = true;
    // For preventing "DOMException: play() failed because the user didn't interact with the document first." in unit-tests.
    WebPlayer.test = true;
  });

	group('ffprobe', () {
		test('bitrate scan', () async {
			expect((await _scan(sources.file[0]))['format']['bit_rate'], '1261590');
			expect((await _scan(sources.file[1]))['format']['bit_rate'], '1197518');
			expect((await _scan(sources.file[2]))['format']['bit_rate'], '1330266');
			expect((await _scan(sources.file[3]))['format']['bit_rate'], '1222688');
		});
	});
}