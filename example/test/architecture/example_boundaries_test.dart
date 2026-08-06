import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _importPattern = RegExp("^import\\s+'([^']+)'", multiLine: true);

Iterable<File> _dartFiles(Directory directory) => directory
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));

Iterable<String> _imports(File file) sync* {
  final source = file.readAsStringSync();
  for (final match in _importPattern.allMatches(source)) {
    yield match.group(1)!;
  }
}

void main() {
  test('architecture apps do not import one another', () {
    final appsRoot = Directory('lib/apps');
    final offenders = <String>[];

    for (final app in appsRoot.listSync().whereType<Directory>()) {
      final appName = app.uri.pathSegments
          .where((part) => part.isNotEmpty)
          .last;
      for (final file in _dartFiles(app)) {
        for (final import in _imports(file)) {
          String? importedApp;
          if (import.startsWith('package:example/apps/')) {
            importedApp = import.split('/')[2];
          } else if (import.startsWith('.')) {
            final resolved = file.parent.uri.resolve(import).path;
            final marker = '/lib/apps/';
            final markerIndex = resolved.indexOf(marker);
            if (markerIndex >= 0) {
              importedApp = resolved
                  .substring(markerIndex + marker.length)
                  .split('/')
                  .first;
            }
          }
          if (importedApp != null && importedApp != appName) {
            offenders.add('${file.path} -> $import');
          }
        }
      }
    }

    expect(offenders, isEmpty);
  });

  test('common UI depends only on Flutter and its own presentation files', () {
    final offenders = <String>[];
    for (final file in _dartFiles(Directory('lib/common'))) {
      for (final import in _imports(file)) {
        final isAllowedPackage = import.startsWith('package:flutter/');
        final isDartSdk = import.startsWith('dart:');
        final resolvedPath = file.parent.uri
            .resolve(import)
            .path
            .replaceAll('\\', '/');
        final isLocal =
            !import.contains(':') && resolvedPath.contains('lib/common/');
        if (!isAllowedPackage && !isDartSdk && !isLocal) {
          offenders.add('${file.path} -> $import');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('feature-first routing files do not import composition or UI', () {
    final offenders = <String>[];
    final root = Directory('lib/apps/feature_first/feature');
    for (final file in _dartFiles(root).where(
      (file) => file.parent.path.endsWith('${Platform.pathSeparator}routing'),
    )) {
      for (final import in _imports(file)) {
        if (import.contains('material.dart') ||
            import.contains('page_composition') ||
            import.contains('/view/') ||
            import.contains('repositories/')) {
          offenders.add('${file.path} -> $import');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('isolated apps do not depend on the aggregate launcher', () {
    final offenders = <String>[];
    for (final file in _dartFiles(Directory('lib/apps'))) {
      for (final import in _imports(file)) {
        if (import.contains('example_app_launcher.dart')) {
          offenders.add('${file.path} -> $import');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('only the aggregate launcher imports multiple example apps', () {
    final offenders = <String>[];
    for (final file in _dartFiles(Directory('lib'))) {
      final importedApps = <String>{};
      for (final import in _imports(file)) {
        if (import.startsWith('package:example/apps/')) {
          importedApps.add(import.split('/')[2]);
        } else if (import.startsWith('.')) {
          final resolved = file.parent.uri.resolve(import).path;
          final marker = '/lib/apps/';
          final markerIndex = resolved.indexOf(marker);
          if (markerIndex < 0) {
            continue;
          }
          importedApps.add(
            resolved.substring(markerIndex + marker.length).split('/').first,
          );
        }
      }
      if (importedApps.length > 1 &&
          !file.path.endsWith(
            'lib${Platform.pathSeparator}example_app_launcher.dart',
          )) {
        offenders.add('${file.path} -> ${importedApps.toList()..sort()}');
      }
    }
    expect(offenders, isEmpty);

    final launcherImports = _imports(
      File('lib/example_app_launcher.dart'),
    ).where((import) => import.startsWith('apps/')).toList();
    expect(launcherImports, hasLength(4));
  });

  test('only router-neutral adapter infrastructure imports Rolter', () {
    final root = Directory('lib/apps/router_neutral_adapter');
    final offenders = <String>[];
    for (final file in _dartFiles(root)) {
      final importsRolter = _imports(
        file,
      ).any((import) => import == 'package:rolter/rolter.dart');
      if (importsRolter &&
          !file.path.endsWith(
            'infrastructure${Platform.pathSeparator}rolter_adapter.dart',
          )) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('only isolated entrypoints remain at the example package boundary', () {
    for (final path in [
      'lib/app.dart',
      'lib/core',
      'lib/feature',
      'lib/adapter_example',
      'lib/main_centralized.dart',
      'lib/main_scope_lookup.dart',
      'lib/main_adapter.dart',
    ]) {
      expect(
        FileSystemEntity.typeSync(path),
        FileSystemEntityType.notFound,
        reason: '$path must not compete with the isolated apps',
      );
    }

    for (final path in [
      'lib/main.dart',
      'lib/apps/feature_first/main.dart',
      'lib/apps/centralized_route_owned/main.dart',
      'lib/apps/external_builder_scope/main.dart',
      'lib/apps/router_neutral_adapter/main.dart',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: '$path must be runnable');
    }
  });
}
