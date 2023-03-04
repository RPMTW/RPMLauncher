import 'package:pub_semver/pub_semver.dart';

class GameVersionHandler {
  static Version parse(String id) {
    try {
      try {
        return _parse(id);
      } catch (e) {
        /// Handling snapshot version (e.g. 21w44a)
        final snapshotPattern = RegExp(r'(?:(?<yy>\d\d)w(?<ww>\d\d)[a-z])');
        if (snapshotPattern.hasMatch(id)) {
          return _parseSnapshot(id, snapshotPattern);
        }

        final preVersion = _parsePreVersion(id);
        if (preVersion != null) {
          return _parse(preVersion);
        }

        rethrow;
      }
    } catch (e) {
      throw Exception('Invalid game version: $id ($e)');
    }
  }

  static Version _parse(String id) {
    // Example: 1.19, 1.18 or 1.17 etc.
    final patchIsEmpty = RegExp(r'^\d+\.\d+$').hasMatch(id);
    if (patchIsEmpty) {
      return Version.parse('$id.0');
    }

    return Version.parse(id);
  }

  static Version _parseSnapshot(String id, RegExp snapshotPattern) {
    /// Handling snapshot version (e.g. 21w44a)

    final match = snapshotPattern.allMatches(id).toList().first;

    String toReleaseVer(int year, int week) {
      if (year == 22 && week >= 46 || year >= 23) {
        return '1.19.3';
      } else if (year == 22 && week == 24) {
        return '1.19.1';
      } else if (year == 22 && week >= 11 && week <= 19) {
        return '1.19';
      } else if (year == 22 && week >= 3 && week <= 7) {
        return '1.18.2';
      } else if (year == 21 && week >= 37) {
        return '1.18';
      } else if (year == 21 && (week >= 3 && week <= 20)) {
        return '1.17';
      } else if (year == 20 && week >= 6) {
        return '1.16';
      } else if (year == 19 && week >= 34) {
        return '1.15.2';
      } else if (year == 18 && week >= 43 || year == 19 && week <= 14) {
        return '1.14';
      } else if (year == 18 && week >= 30 && week <= 33) {
        return '1.13.1';
      } else if (year == 17 && week >= 43 || year == 18 && week <= 22) {
        return '1.13';
      } else if (year == 17 && week == 31) {
        return '1.12.1';
      } else if (year == 17 && week >= 6 && week <= 18) {
        return '1.12';
      } else if (year == 16 && week == 50) {
        return '1.11.1';
      } else if (year == 16 && week >= 32 && week <= 44) {
        return '1.11';
      } else if (year == 16 && week >= 20 && week <= 21) {
        return '1.10';
      } else if (year == 16 && week >= 14 && week <= 15) {
        return '1.9.3';
      } else if (year == 15 && week >= 31 || year == 16 && week <= 7) {
        return '1.9';
      } else if (year == 14 && week >= 2 && week <= 34) {
        return '1.8';
      } else if (year == 13 && week >= 47 && week <= 49) {
        return '1.7.4';
      } else if (year == 13 && week >= 36 && week <= 43) {
        return '1.7.2';
      } else if (year == 13 && week >= 16 && week <= 26) {
        return '1.6';
      } else if (year == 13 && week >= 11 && week <= 12) {
        return '1.5.1';
      } else if (year == 13 && week >= 1 && week <= 10) {
        return '1.5';
      } else if (year == 12 && week >= 49 && week <= 50) {
        return '1.4.6';
      } else if (year == 12 && week >= 32 && week <= 42) {
        return '1.4.2';
      } else if (year == 12 && week >= 15 && week <= 30) {
        return '1.3.1';
      } else if (year == 12 && week >= 3 && week <= 8) {
        return '1.2.1';
      } else if (year == 11 && week >= 47 || year == 12 && week <= 1) {
        return '1.1';
      } else {
        return '1.19';
      }
    }

    int year = int.parse(match.group(1).toString()); //ex: 23 (year 2023)
    int week = int.parse(match.group(2).toString()); //ex: 44 (week 44)

    return _parse(toReleaseVer(year, week));
  }

  static String? _parsePreVersion(String id) {
    String result = id;

    int pos = result.indexOf('-pre');
    if (pos >= 0) result = result.substring(0, pos);

    pos = result.indexOf(' Pre-release ');
    if (pos >= 0) result = result.substring(0, pos);

    pos = result.indexOf(' Pre-Release ');
    if (pos >= 0) result = result.substring(0, pos);

    pos = result.indexOf(' Release Candidate ');
    if (pos >= 0) result = result.substring(0, pos);

    pos = result.indexOf(RegExp(r'-rc\d+$'));
    if (pos >= 0) result = result.substring(0, pos);

    if (result.startsWith(RegExp(r'[a-z]'))) result = result.substring(1);
    if (result.endsWith('a') || result.endsWith('b')) {
      result = result.substring(0, result.length - 1);
    }

    // Remove 1.5_01, 1.5_02, etc.
    pos = result.indexOf('_');
    if (pos >= 0) result = result.substring(0, pos);

    if (result != id) return result;
    return null;
  }
}
