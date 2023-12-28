import 'dart:convert';

import 'package:file/file.dart';
import 'package:patrol_cli/src/base/extensions/core.dart';

class DartDefinesReader {
  DartDefinesReader({
    required Directory projectRoot,
  })  : _projectRoot = projectRoot,
        _fs = projectRoot.fileSystem;

  final Directory _projectRoot;
  final FileSystem _fs;

  Map<String, String> fromCli({required List<String> args}) => _parse(args);

  Map<String, String> fromPatrolEnvFile() {
    final file = _getProjectFile('.patrol.env');

    if (!file.existsSync()) {
      return {};
    }

    final lines = file.readAsLinesSync()
      ..removeWhere((line) => line.trim().isEmpty);
    return _parse(lines);
  }

  Map<String, String> fromDartDefineFile(String path) {
    final file = _getProjectFile(path);

    if (!file.existsSync()) {
      throw FileSystemException("$path doesn't exist");
    }

    final jsonFileString = file.readAsStringSync();
    final variablesMap = (json.decode(jsonFileString) as Map<String, Object?>)
        .map((key, value) => MapEntry(key, '$value'));

    return variablesMap;
  }

  Map<String, String> _parse(List<String> args) {
    final map = <String, String>{};
    var currentKey = ' ';
    for (final arg in args) {
      if (!arg.contains('=') && currentKey != ' ') {
        map[currentKey] = '${map[currentKey]}, $arg';
        continue;
      }
      final parts = arg.splitFirst('=');
      currentKey = parts.first;
      if (currentKey.contains(' ')) {
        throw FormatException('key "$currentKey" contains whitespace');
      }

      final value = parts.elementAt(1);
      map[currentKey] = value;
    }

    return map;
  }

  File _getProjectFile(String path) {
    final filePath = _fs.path.join(_projectRoot.path, path);
    return _fs.file(filePath);
  }
}
