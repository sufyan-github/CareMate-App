import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

GoldenFileComparator installTolerantGoldenComparator({
  double precisionTolerance = 0.01,
}) {
  final previous = goldenFileComparator;
  if (previous is! LocalFileComparator) return previous;

  goldenFileComparator = _TolerantGoldenFileComparator(
    previous.basedir.resolve('caremate_golden_test.dart'),
    precisionTolerance: precisionTolerance,
  );
  return previous;
}

class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : assert(precisionTolerance >= 0 && precisionTolerance <= 1),
       _precisionTolerance = precisionTolerance;

  final double _precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _precisionTolerance) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
