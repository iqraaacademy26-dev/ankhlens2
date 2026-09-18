import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cartouche_engine.dart';
import 'sign_mapper.dart';

/// Loads assets/data/phoneme_to_sign_map.json once and builds the
/// [SignMapper] from it. Kept as a FutureProvider (not a startup-blocking
/// call) since it's only needed once the user opens the Cartouche Maker.
final signMapperProvider = FutureProvider<SignMapper>((ref) async {
  final jsonString =
      await rootBundle.loadString('assets/data/phoneme_to_sign_map.json');
  return SignMapper.fromJson(jsonString);
});

/// The cartouche engine, ready once [signMapperProvider] resolves. UI code
/// should watch this via `.when(...)` and only show the name input once
/// it's ready (it's near-instant after first load).
final cartoucheEngineProvider = FutureProvider<CartoucheEngine>((ref) async {
  final signMapper = await ref.watch(signMapperProvider.future);
  return CartoucheEngine(signMapper: signMapper);
});
