/// Validation harness for the LOCAL QuickWorkoutEngine (the on-device,
/// rule-based engine the home-screen Quick button uses 95%+ of the time).
///
/// NO AI. NO Render. Pure-Dart synchronous generation against the bundled
/// `assets/data/exercise_library.json`.
///
/// Run:
///   cd mobile/flutter
///   flutter test test/services/quick_workout_engine_validation_test.dart
///
/// Outputs (one per scenario, flushed immediately):
///   test_output/quick_workout_engine_<ts>/workouts.csv
///   test_output/quick_workout_engine_<ts>/json/scenario_NNN.json
///   stdout: per-scenario status line.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/services/quick_workout_engine.dart';
import 'package:fitwiz/services/offline_workout_generator.dart';

const _userId = 'd54e6652-fdf1-4ca0-82d1-23d7c02df294';  // reviewer@fitwiz.us

// Equipment subsets matching the scenarios MD.
const _equipFull = <String>[
  'barbell','dumbbells','cable_machine','squat_rack','bench','pull_up_bar',
  'kettlebell','leg_press_machine','lat_pulldown','smith_machine','treadmill',
  'rowing_machine','stationary_bike','elliptical','resistance_bands',
];
const _equipBw = <String>[];
const _equipDb = <String>['dumbbells','bench','resistance_bands'];
const _equipKb = <String>['kettlebell'];
const _equipMach = <String>['cable_machine','leg_press_machine','lat_pulldown','smith_machine'];
const _equipBands = <String>['resistance_bands'];
const _equipNoBb = <String>['dumbbells','cable_machine','bench','pull_up_bar','kettlebell','lat_pulldown','resistance_bands'];
const _equipFw = <String>['barbell','dumbbells','kettlebell','bench','pull_up_bar'];
const _equipDb1 = <String>['dumbbells'];
const _equipHome = <String>['dumbbells','resistance_bands','pull_up_bar'];
const _equipCardio = <String>['treadmill','rowing_machine','stationary_bike','elliptical'];
const _equipBwBands = <String>['resistance_bands'];

class Scenario {
  final int idx;
  final int block;
  final String label;
  final int duration;
  final String? focus;       // cardio | strength | stretch | full_body | null
  final String difficulty;   // easy | medium | hard | hell
  final String? mood;
  final bool useSupersets;
  final List<String> equipment;
  final List<String> injuries;
  final String fitnessLevel; // beginner | intermediate | advanced
  final String? goal;        // hypertrophy | strength | endurance | etc.

  const Scenario({
    required this.idx,
    required this.block,
    required this.label,
    required this.duration,
    this.focus,
    this.difficulty = 'medium',
    this.mood,
    this.useSupersets = true,
    this.equipment = const [],
    this.injuries = const [],
    this.fitnessLevel = 'intermediate',
    this.goal,
  });

  Map<String, dynamic> toJson() => {
    'idx': idx,
    'block': block,
    'label': label,
    'duration': duration,
    'focus': focus,
    'difficulty': difficulty,
    'mood': mood,
    'useSupersets': useSupersets,
    'equipment': equipment,
    'injuries': injuries,
    'fitnessLevel': fitnessLevel,
    'goal': goal,
  };
}

List<Scenario> _buildScenarios() {
  final s = <Scenario>[];
  int i = 0;

  // Block 1 — Fitness × Focus × Duration × Difficulty Cartesian (504 scenarios).
  const fitnesses = ['beginner', 'intermediate', 'advanced'];
  const focuses1 = ['full_body', 'strength', 'cardio', 'stretch', 'upper_body', 'lower_body', 'core'];
  const durations1 = [5, 10, 15, 20, 25, 30];
  const difficulties = ['easy', 'medium', 'hard', 'hell'];
  for (final fl in fitnesses) {
    for (final f in focuses1) {
      for (final d in durations1) {
        for (final diff in difficulties) {
          i++;
          s.add(Scenario(
            idx: i, block: 1,
            label: '$fl/$f/${d}min/$diff',
            duration: d, focus: f, difficulty: diff,
            fitnessLevel: fl, equipment: _equipFull,
          ));
        }
      }
    }
  }

  // Block 2 — Equipment subset stress (240).
  final equipPool = <List<dynamic>>[
    ['full', _equipFull], ['bodyweight', _equipBw], ['dumbbells', _equipDb],
    ['kettlebells', _equipKb], ['machines', _equipMach], ['bands', _equipBands],
    ['no_barbell', _equipNoBb], ['free_weights', _equipFw],
    ['single_dumbbell', _equipDb1], ['home_basic', _equipHome],
    ['cardio_machines', _equipCardio], ['bw+bands', _equipBwBands],
  ];
  const eqFocuses = ['strength', 'full_body', 'cardio', 'stretch', 'core'];
  final eqVariants = <List<dynamic>>[
    ['beginner', 'easy', 10], ['intermediate', 'medium', 20],
    ['advanced', 'hard', 25], ['intermediate', 'hell', 30],
  ];
  for (final eq in equipPool) {
    final eqName = eq[0] as String;
    final eqList = eq[1] as List<String>;
    for (final f in eqFocuses) {
      for (final v in eqVariants) {
        i++;
        s.add(Scenario(
          idx: i, block: 2,
          label: 'equip=$eqName/$f/${v[0]}/${v[1]}/${v[2]}min',
          duration: v[2] as int, focus: f, difficulty: v[1] as String,
          fitnessLevel: v[0] as String, equipment: eqList,
        ));
      }
    }
  }

  // Block 3 — Injury combos × Focus × Difficulty (255).
  // Expanded to ≥25% cross-surface injury coverage (250/1000 target).
  final injuryCases = <List<dynamic>>[
    ['none', <String>[]], ['knee', ['knee']], ['shoulder', ['shoulder']],
    ['lower_back', ['lower_back']], ['wrist', ['wrist']], ['ankle', ['ankle']],
    ['hip', ['hip']], ['elbow', ['elbow']], ['neck', ['neck']],
    ['knee+shoulder', ['knee', 'shoulder']],
    ['knee+lower_back', ['knee', 'lower_back']],
    ['shoulder+wrist', ['shoulder', 'wrist']],
    ['shoulder+elbow', ['shoulder', 'elbow']],
    ['lower_back+hip', ['lower_back', 'hip']],
    ['knee+ankle', ['knee', 'ankle']],
    ['multi-3', ['knee', 'shoulder', 'lower_back']],
    ['multi-4', ['knee', 'shoulder', 'lower_back', 'wrist']],
    ['multi-5', ['knee', 'shoulder', 'lower_back', 'wrist', 'ankle']],
    ['all-7', ['knee', 'shoulder', 'lower_back', 'wrist', 'ankle', 'hip', 'elbow']],
    ['elbow+wrist', ['elbow', 'wrist']],
    ['hip+ankle', ['hip', 'ankle']],
  ];
  // Skip 'none' for the dedicated-injury sweep so all 255 of these are injury-positive.
  final injuryOnlyCases = injuryCases.skip(1).toList();  // 20 cases
  const injuryFocuses = ['full_body', 'strength', 'cardio', 'upper_body', 'lower_body'];  // 5
  const injuryDiffs = ['easy', 'medium', 'hard'];  // 3
  // Layered: 20 × 5 × 3 = 300, capped to 255 (the cap keeps Block 6 padding
  // budget reasonable while exceeding the 250 / 25% threshold cleanly).
  int b3Count = 0;
  for (final ic in injuryOnlyCases) {
    final label = ic[0] as String;
    final inj = (ic[1] as List).cast<String>();
    for (final f in injuryFocuses) {
      for (final diff in injuryDiffs) {
        if (b3Count >= 255) break;
        i++;
        b3Count++;
        s.add(Scenario(
          idx: i, block: 3,
          label: 'inj=$label/$f/$diff',
          duration: 20, focus: f, difficulty: diff,
          injuries: inj, equipment: _equipFull,
        ));
      }
      if (b3Count >= 255) break;
    }
    if (b3Count >= 255) break;
  }

  // Block 4 — Mood × Goal × Focus (90).
  const moods = <String?>['energetic', 'tired', 'focused', 'angry', 'calm', null];
  const goals = ['hypertrophy', 'strength', 'endurance', 'fat_loss', 'general_fitness'];
  const moodFocuses = ['full_body', 'strength', 'cardio'];
  for (final mood in moods) {
    for (final goal in goals) {
      for (final f in moodFocuses) {
        i++;
        s.add(Scenario(
          idx: i, block: 4,
          label: 'mood=${mood ?? "null"}/goal=$goal/$f',
          duration: 20, focus: f, mood: mood, goal: goal,
          equipment: _equipFull,
        ));
      }
    }
  }

  // Block 5 — Supersets toggle × Duration × Focus (48).
  const sFocuses = ['full_body', 'strength', 'upper_body', 'lower_body'];
  const sDurations = [10, 20, 30];
  for (final use in [true, false]) {
    for (final f in sFocuses) {
      for (final d in sDurations) {
        for (final diff in ['medium', 'hard']) {
          i++;
          s.add(Scenario(
            idx: i, block: 5,
            label: 'supersets=$use/$f/${d}min/$diff',
            duration: d, focus: f, difficulty: diff,
            useSupersets: use, equipment: _equipFull,
          ));
        }
      }
    }
  }

  // Block 6 — Pad to 1000 with rotational fill (deterministic variety).
  while (s.length < 1000) {
    final n = s.length;
    final fl = fitnesses[n % 3];
    final f = focuses1[n % focuses1.length];
    final d = durations1[n % durations1.length];
    final diff = difficulties[n % 4];
    final eqEntry = equipPool[n % equipPool.length];
    final eqName = eqEntry[0] as String;
    final eqList = (eqEntry[1] as List).cast<String>();
    final injEntry = injuryCases[n % injuryCases.length];
    final injLabel = injEntry[0] as String;
    final inj = (injEntry[1] as List).cast<String>();
    final mood = moods[n % moods.length];
    final goal = goals[n % goals.length];
    i++;
    s.add(Scenario(
      idx: i, block: 6,
      label: 'pad $fl/$f/${d}min/$diff/$eqName/inj=$injLabel/mood=${mood ?? "-"}/goal=$goal',
      duration: d, focus: f, difficulty: diff,
      fitnessLevel: fl, equipment: eqList, injuries: inj,
      mood: mood, goal: goal,
    ));
  }

  return s;
}

void main() {
  late List<OfflineExercise> library;
  late Directory outDir;
  late File csvFile;

  setUpAll(() async {
    // Load the bundled exercise library JSON directly (NOT via rootBundle —
    // that requires a Flutter app context). We open the asset file from disk.
    final asset = File('assets/data/exercise_library.json');
    if (!asset.existsSync()) {
      fail('exercise_library.json not found at ${asset.absolute.path} '
           '(run `flutter test` from mobile/flutter/)');
    }
    final raw = await asset.readAsString();
    final list = jsonDecode(raw) as List;
    library = list
        .map((e) => OfflineExercise.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(library.length, greaterThan(100),
        reason: 'expected a sizeable bundled library');
    // ignore: avoid_print
    print('[harness] loaded ${library.length} exercises from bundle');

    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .substring(0, 15);
    outDir = Directory('test_output/quick_workout_engine_$ts');
    outDir.createSync(recursive: true);
    Directory('${outDir.path}/json').createSync(recursive: true);

    csvFile = File('${outDir.path}/workouts.csv');
    csvFile.writeAsStringSync([
      'idx', 'block', 'label', 'duration_target', 'focus', 'difficulty',
      'mood', 'use_supersets', 'fitness_level', 'goal',
      'equipment_count', 'equipment_pipe', 'injuries_pipe',
      'workout_name', 'workout_type', 'workout_difficulty',
      'n_exercises', 'exercise_names_pipe',
      'per_exercise_sets', 'per_exercise_reps', 'per_exercise_weight_kg',
      'per_exercise_rest_seconds', 'per_exercise_muscle_group',
      'estimated_duration_min', 'total_volume_kg', 'latency_ms', 'error',
    ].join(',') + '\n');

    // ignore: avoid_print
    print('[harness] output → ${outDir.path}');
  });

  test('Quick workout engine — full validation sweep', () {
    final scenarios = _buildScenarios();
    final engine = QuickWorkoutEngine();
    var ok = 0;
    var failed = 0;

    for (final sc in scenarios) {
      final t0 = DateTime.now().microsecondsSinceEpoch;
      String? error;
      Map<String, dynamic>? workoutJson;
      var nExercises = 0;
      String wName = '';
      String wType = '';
      String wDiff = '';
      final sets = <String>[];
      final reps = <String>[];
      final weights = <String>[];
      final rests = <String>[];
      final muscles = <String>[];
      final names = <String>[];
      double totalVolume = 0;
      int? estDuration;

      try {
        final workout = engine.generate(
          userId: _userId,
          durationMinutes: sc.duration,
          focus: sc.focus,
          difficulty: sc.difficulty,
          mood: sc.mood,
          useSupersets: sc.useSupersets,
          equipment: sc.equipment,
          injuries: sc.injuries,
          exerciseLibrary: library,
          fitnessLevel: sc.fitnessLevel,
          goal: sc.goal,
        );
        workoutJson = workout.toJson();
        wName = workout.name ?? '';
        wType = workout.type ?? '';
        wDiff = workout.difficulty ?? '';
        estDuration = workout.durationMinutes;
        // Parse exercises_json (list of maps with sets/reps/weight/rest/muscle).
        final exJson = workout.exercisesJson;
        List<dynamic> exList;
        if (exJson is List) {
          exList = exJson;
        } else if (exJson is String) {
          exList = jsonDecode(exJson) as List<dynamic>;
        } else {
          exList = const [];
        }
        nExercises = exList.length;
        for (final raw in exList) {
          final e = (raw as Map).cast<String, dynamic>();
          names.add((e['name'] ?? '').toString());
          final s = (e['sets'] ?? '').toString();
          final r = (e['reps'] ?? '').toString();
          final w = (e['weight_kg'] ?? e['weight'] ?? '').toString();
          final rest = (e['rest_seconds'] ?? '').toString();
          final m = (e['muscle_group'] ?? e['target_muscle'] ?? '').toString();
          sets.add(s); reps.add(r); weights.add(w); rests.add(rest); muscles.add(m);
          // Approximate volume.
          final si = int.tryParse(s) ?? 0;
          final ri = int.tryParse(r) ?? 0;
          final wf = double.tryParse(w) ?? 0;
          totalVolume += si * ri * wf;
        }
        ok++;
      } catch (e, st) {
        error = '$e';
        // ignore: avoid_print
        print('[${sc.idx}] FAILED: $e\n$st');
        failed++;
      }

      final latencyMs =
          ((DateTime.now().microsecondsSinceEpoch - t0) / 1000).round();

      // Per-scenario JSON file.
      final jsonOut = {
        'scenario': sc.toJson(),
        'workout': workoutJson,
        'extracted': {
          'workout_name': wName,
          'workout_type': wType,
          'workout_difficulty': wDiff,
          'n_exercises': nExercises,
          'exercise_names': names,
          'per_exercise_sets': sets,
          'per_exercise_reps': reps,
          'per_exercise_weight_kg': weights,
          'per_exercise_rest_seconds': rests,
          'per_exercise_muscle_group': muscles,
          'estimated_duration_min': estDuration,
          'total_volume_kg': totalVolume,
        },
        'latency_ms': latencyMs,
        'error': error,
      };
      File('${outDir.path}/json/scenario_${sc.idx.toString().padLeft(3, "0")}.json')
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(jsonOut));

      // CSV row (escape for commas/newlines via JSON encoding strings that need it).
      String esc(String v) {
        if (v.contains(',') || v.contains('"') || v.contains('\n')) {
          return '"${v.replaceAll('"', '""')}"';
        }
        return v;
      }
      final row = [
        sc.idx.toString(), sc.block.toString(), esc(sc.label),
        sc.duration.toString(), esc(sc.focus ?? ''), sc.difficulty,
        esc(sc.mood ?? ''), sc.useSupersets.toString(),
        sc.fitnessLevel, esc(sc.goal ?? ''),
        sc.equipment.length.toString(), esc(sc.equipment.join('|')),
        esc(sc.injuries.join('|')),
        esc(wName), esc(wType), esc(wDiff),
        nExercises.toString(), esc(names.join('|')),
        esc(sets.join('|')), esc(reps.join('|')),
        esc(weights.join('|')), esc(rests.join('|')),
        esc(muscles.join('|')),
        (estDuration ?? '').toString(),
        totalVolume.toStringAsFixed(1),
        latencyMs.toString(),
        esc(error ?? ''),
      ].join(',') + '\n';
      // Append + flush by writing in append mode.
      csvFile.writeAsStringSync(row, mode: FileMode.append, flush: true);

      // ignore: avoid_print
      print(
        '[${sc.idx}/${scenarios.length}] block=${sc.block} '
        'name="$wName" '
        'n_ex=$nExercises latency=${latencyMs}ms '
        '${error == null ? "OK" : "ERR=$error"} '
        '| ${sc.label}',
      );
    }

    // Summary.
    // ignore: avoid_print
    print('\n[harness] Done. ok=$ok failed=$failed total=${scenarios.length}');
    // ignore: avoid_print
    print('[harness] CSV  → ${csvFile.path}');
    // ignore: avoid_print
    print('[harness] JSON → ${outDir.path}/json/');

    expect(failed, 0,
        reason: 'Some scenarios failed — check stdout + per-scenario JSON');
    expect(ok, scenarios.length);
  });
}
