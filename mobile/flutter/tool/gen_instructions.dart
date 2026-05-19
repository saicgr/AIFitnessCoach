// Standalone generator: runs the app's own deterministic instruction engine
// (lib/screens/workout/shared/exercise_instruction_copy.dart) over a batch of
// exercises and emits the setup steps + breathing cues + form tips as JSON.
//
// This reuses the project's already-vetted, technique-correct instruction
// content rather than re-authoring it. The Python orchestrator
// (backend/scripts/rewrite_exercise_instructions.py) wraps the output with
// per-exercise interpolation, citations, validation, and the DB write.
//
// Usage:  dart run tool/gen_instructions.dart <input.json> <output.json>
//   input.json  : [{"id": "...", "name": "...", "equipment": "..."}, ...]
//   output.json : [{"id": "...", "setup": [...], "breathing": [...],
//                   "tips": [...]}, ...]

import 'dart:convert';
import 'dart:io';

import 'package:fitwiz/screens/workout/shared/exercise_instruction_copy.dart';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: dart run tool/gen_instructions.dart <in.json> <out.json>');
    exit(2);
  }
  final input = jsonDecode(File(args[0]).readAsStringSync()) as List;
  final out = <Map<String, dynamic>>[];
  for (final raw in input) {
    final ex = raw as Map<String, dynamic>;
    final name = (ex['name'] ?? '').toString();
    final equip = ex['equipment']?.toString();
    out.add({
      'id': ex['id'],
      'setup': getSetupSteps(name, equipment: equip),
      'breathing': getBreathingCues(name, equipment: equip),
      'tips': getFormTips(name, equipment: equip),
    });
  }
  File(args[1]).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
  stdout.writeln('generated ${out.length} instruction sets -> ${args[1]}');
}
