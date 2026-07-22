import 'dart:convert';
import 'dart:io';

void main() {
  final baseline = jsonDecode(
    File('tool/coverage_baseline.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final minimum = baseline['lineCoveragePercent']! as num;
  final lines = File('coverage/lcov.info').readAsLinesSync();

  var found = 0;
  var hit = 0;
  for (final line in lines) {
    if (line.startsWith('LF:')) {
      found += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hit += int.parse(line.substring(3));
    }
  }
  if (found == 0) {
    stderr.writeln('No coverable lines found in coverage/lcov.info.');
    exitCode = 1;
    return;
  }

  final percent = hit * 100 / found;
  stdout.writeln(
    'Line coverage: $hit/$found (${percent.toStringAsFixed(2)}%); '
    'required: ${minimum.toStringAsFixed(2)}%.',
  );
  if (percent + 0.000001 < minimum) {
    stderr.writeln(
      'Coverage regressed. Update code/tests, or change the baseline with a '
      'reviewed explanation in the pull request.',
    );
    exitCode = 1;
  }
}
