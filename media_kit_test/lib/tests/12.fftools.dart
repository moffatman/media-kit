import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class FFToolsDemo extends StatefulWidget {
  const FFToolsDemo({Key? key}) : super(key: key);

  @override
  State<FFToolsDemo> createState() => _FFToolsDemoState();
}

class _FFToolsDemoState extends State<FFToolsDemo> {
	String result = 'nothing';

	@override
	void initState() {
		super.initState();
		FFTools.ffmpeg(
			arguments: ['-h']
		).then((ret) {
			setState(() {
				result = 'code: ${ret.returnCode}\noutput: ${ret.output}';
			});
		});
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: Center(
				child: Text(result)
			)
		);
	}
}