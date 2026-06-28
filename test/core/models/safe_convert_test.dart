import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/core/models/safe_convert.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // toInt
  // ─────────────────────────────────────────────────────────────────────────
  group('toInt', () {
    test('null → default 0', () => expect(toInt(null), 0));
    test('null → custom default', () => expect(toInt(null, defaultValue: 99), 99));
    test('int identity', () => expect(toInt(42), 42));
    test('double truncates', () => expect(toInt(3.9), 3));
    test('bool true → 1', () => expect(toInt(true), 1));
    test('bool false → 0', () => expect(toInt(false), 0));
    test('numeric string', () => expect(toInt('17'), 17));
    test('float string truncates', () => expect(toInt('3.7'), 3));
    test('non-numeric string → default', () => expect(toInt('abc'), 0));
    test('empty string → default', () => expect(toInt(''), 0));
    test('object → default', () => expect(toInt(Object()), 0));
    test('zero int', () => expect(toInt(0), 0));
    test('negative int', () => expect(toInt(-5), -5));
    test('negative string', () => expect(toInt('-10'), -10));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // toDouble
  // ─────────────────────────────────────────────────────────────────────────
  group('toDouble', () {
    test('null → 0.0', () => expect(toDouble(null), 0.0));
    test('null → custom default', () => expect(toDouble(null, defaultValue: 1.5), 1.5));
    test('double identity', () => expect(toDouble(3.14), 3.14));
    test('int → double', () => expect(toDouble(5), 5.0));
    test('bool true → 1.0', () => expect(toDouble(true), 1.0));
    test('bool false → 0.0', () => expect(toDouble(false), 0.0));
    test('numeric string', () => expect(toDouble('2.15'), 2.15));
    test('integer string', () => expect(toDouble('10'), 10.0));
    test('non-numeric string → default', () => expect(toDouble('abc'), 0.0));
    test('empty string → default', () => expect(toDouble(''), 0.0));
    test('object → default', () => expect(toDouble(Object()), 0.0));
    test('negative double', () => expect(toDouble(-1.5), -1.5));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // toBool
  // ─────────────────────────────────────────────────────────────────────────
  group('toBool', () {
    test('null → false', () => expect(toBool(null), false));
    test('null → custom default true', () => expect(toBool(null, defaultValue: true), true));
    test('bool true identity', () => expect(toBool(true), true));
    test('bool false identity', () => expect(toBool(false), false));
    test('int 1 → true', () => expect(toBool(1), true));
    test('int 0 → false', () => expect(toBool(0), false));
    test('int 5 → true', () => expect(toBool(5), true));
    test('double 1.0 → true', () => expect(toBool(1.0), true));
    test('double 0.0 → false', () => expect(toBool(0.0), false));
    test('string "true" → true', () => expect(toBool('true'), true));
    test('string "false" → false', () => expect(toBool('false'), false));
    test('string "TRUE" case-insensitive', () => expect(toBool('TRUE'), true));
    test('string "FALSE" case-insensitive', () => expect(toBool('FALSE'), false));
    test('string "1" → true', () => expect(toBool('1'), true));
    test('string "0" → false', () => expect(toBool('0'), false));
    test('unknown string → default false', () => expect(toBool('yes'), false));
    test('empty string → default false', () => expect(toBool(''), false));
    test('object → default', () => expect(toBool(Object()), false));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // toString (the local function, not Dart's Object.toString)
  // ─────────────────────────────────────────────────────────────────────────
  group('toString (safe_convert)', () {
    test('null → ""', () => expect(toString(null), ''));
    test('null → custom default', () => expect(toString(null, defaultValue: 'N/A'), 'N/A'));
    test('string identity', () => expect(toString('Budi'), 'Budi'));
    test('int → string', () => expect(toString(42), '42'));
    test('double → string', () => expect(toString(3.14), '3.14'));
    test('bool true → "true"', () => expect(toString(true), 'true'));
    test('bool false → "false"', () => expect(toString(false), 'false'));
    test('object → default', () => expect(toString(Object()), ''));
    test('empty string stays empty', () => expect(toString(''), ''));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // toMap
  // ─────────────────────────────────────────────────────────────────────────
  group('toMap', () {
    test('null → {}', () => expect(toMap(null), <String, dynamic>{}));
    test('null with custom default', () {
      final def = {'key': 'val'};
      expect(toMap(null, defaultValue: def), def);
    });
    test('Map<String,dynamic> identity', () {
      final map = {'a': 1, 'b': 'x'};
      expect(toMap(map), map);
    });
    test('non-map value → {}', () => expect(toMap('not a map'), <String, dynamic>{}));
    test('int value → {}', () => expect(toMap(5), <String, dynamic>{}));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // toList
  // ─────────────────────────────────────────────────────────────────────────
  group('toList', () {
    test('null → []', () => expect(toList(null), []));
    test('null → custom default', () => expect(toList(null, defaultValue: [1, 2]), [1, 2]));
    test('list identity', () => expect(toList([1, 2, 3]), [1, 2, 3]));
    test('non-list value → []', () => expect(toList('not a list'), []));
    test('int value → []', () => expect(toList(42), []));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // asInt — map-key variant
  // ─────────────────────────────────────────────────────────────────────────
  group('asInt (map key)', () {
    test('null json → default', () => expect(asInt(null, 'day'), 0));
    test('key missing → default', () => expect(asInt({}, 'day'), 0));
    test('key present, int', () => expect(asInt({'day': 14}, 'day'), 14));
    test('key present, string int', () => expect(asInt({'day': '7'}, 'day'), 7));
    test('key present, double', () => expect(asInt({'day': 3.9}, 'day'), 3));
    test('key present, invalid string → 0', () => expect(asInt({'day': 'x'}, 'day'), 0));
    test('custom defaultValue respected', () => expect(asInt(null, 'day', defaultValue: 5), 5));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // asDouble — map-key variant
  // ─────────────────────────────────────────────────────────────────────────
  group('asDouble (map key)', () {
    test('null json → 0.0', () => expect(asDouble(null, 'weight'), 0.0));
    test('key missing → 0.0', () => expect(asDouble({}, 'weight'), 0.0));
    test('key present, double', () => expect(asDouble({'weight': 2.15}, 'weight'), 2.15));
    test('key present, int', () => expect(asDouble({'weight': 3}, 'weight'), 3.0));
    test('key present, string double', () => expect(asDouble({'weight': '0.4'}, 'weight'), 0.4));
    test('key present, invalid string → 0.0', () => expect(asDouble({'weight': 'x'}, 'weight'), 0.0));
    test('custom defaultValue respected', () {
      expect(asDouble(null, 'weight', defaultValue: 0.4), 0.4);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // asBool — map-key variant
  // ─────────────────────────────────────────────────────────────────────────
  group('asBool (map key)', () {
    test('null json → false', () => expect(asBool(null, 'isActive'), false));
    test('key missing → false', () => expect(asBool({}, 'isActive'), false));
    test('key present, bool true', () => expect(asBool({'isActive': true}, 'isActive'), true));
    test('key present, bool false', () => expect(asBool({'isActive': false}, 'isActive'), false));
    test('key present, string "true"', () => expect(asBool({'isActive': 'true'}, 'isActive'), true));
    test('custom defaultValue true', () {
      expect(asBool(null, 'isActive', defaultValue: true), true);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // asString — map-key variant
  // ─────────────────────────────────────────────────────────────────────────
  group('asString (map key)', () {
    test('null json → ""', () => expect(asString(null, 'name'), ''));
    test('key missing → ""', () => expect(asString({}, 'name'), ''));
    test('key present, string', () => expect(asString({'name': 'Budi Santoso'}, 'name'), 'Budi Santoso'));
    test('key present, int', () => expect(asString({'name': 42}, 'name'), '42'));
    test('custom defaultValue', () {
      expect(asString(null, 'name', defaultValue: 'Unknown'), 'Unknown');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // asMap — map-key variant
  // ─────────────────────────────────────────────────────────────────────────
  group('asMap (map key)', () {
    test('null json → {}', () => expect(asMap(null, 'summary'), <String, dynamic>{}));
    test('key missing → {}', () => expect(asMap({}, 'summary'), <String, dynamic>{}));
    test('key present, valid map', () {
      final nested = {'fcr': 1.42};
      expect(asMap({'summary': nested}, 'summary'), nested);
    });
    test('key present, invalid type → {}', () {
      expect(asMap({'summary': 'not-a-map'}, 'summary'), <String, dynamic>{});
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // asList — map-key variant
  // ─────────────────────────────────────────────────────────────────────────
  group('asList (map key)', () {
    test('null json → []', () => expect(asList(null, 'items'), []));
    test('key missing → []', () => expect(asList({}, 'items'), []));
    test('key present, list', () => expect(asList({'items': [1, 2, 3]}, 'items'), [1, 2, 3]));
    test('key present, non-list → []', () => expect(asList({'items': 'x'}, 'items'), []));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // asListInt
  // ─────────────────────────────────────────────────────────────────────────
  group('asListInt', () {
    test('null json → []', () => expect(asListInt(null, 'days'), <int>[]));
    test('int list', () => expect(asListInt({'days': [1, 7, 14]}, 'days'), [1, 7, 14]));
    test('string int list', () => expect(asListInt({'days': ['1', '7']}, 'days'), [1, 7]));
    test('mixed list', () => expect(asListInt({'days': [1, '2', 3.0]}, 'days'), [1, 2, 3]));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // asListString
  // ─────────────────────────────────────────────────────────────────────────
  group('asListString', () {
    test('null json → []', () => expect(asListString(null, 'tags'), <String>[]));
    test('string list', () {
      expect(asListString({'tags': ['FCR baik', 'Mortalitas rendah']}, 'tags'),
          ['FCR baik', 'Mortalitas rendah']);
    });
    test('mixed list → all to string', () {
      expect(asListString({'tags': [1, true, 'ok']}, 'tags'), ['1', 'true', 'ok']);
    });
  });
}
