/*
 * Copyright (c) 2024 Angelo Cassano
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

import 'dart:async';
import 'dart:io';

import 'package:barrel_annotation/barrel_annotation.dart';
import 'package:barrel_generator/src/contexts/barrel_context.dart';
import 'package:barrel_generator/src/processors/barrel_clean_up_processor.dart';
import 'package:barrel_generator/src/processors/barrel_folder_processor.dart';
import 'package:barrel_generator/src/processors/barrel_output_processor.dart';
import 'package:barrel_generator/src/processors/barrel_writer_processor.dart';
import 'package:barrel_generator/src/utils/path.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// A generator that creates barrel files for a given project
class BarrelGenerator extends Generator {
  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) {
    final barrelConfigAnnotation = library
        .annotatedWith(
          TypeChecker.fromRuntime(BarrelConfig),
          throwOnUnresolved: false,
        )
        .firstOrNull;

    if (barrelConfigAnnotation == null) {
      return null;
    }

    final strRootFolder = _rootFolder;
    final context = _getContext(
      barrelConfigAnnotation.annotation,
      strRootFolder,
    );

    _generate(library.element.source.fullName, context);

    return null;
  }

  void _generate(String rootFolder, BarrelContext context) {
    final strSrcFolder = _getSrcFolder(rootFolder);
    final srcFolder = Directory(strSrcFolder);

    BarrelCleanUpProcessor().process();
    _exploreFolder(srcFolder, context);
  }

  void _exploreFolder(Directory folder, BarrelContext context) {
    final folderContext = BarrelFolderProcessor(
      folder,
      context: context,
    ).process();

    final data = BarrelOutputProcessor(folderContext).process();
    final folderName = folder.path.split(Platform.pathSeparator).last;
    final barrelPath = '${folder.path}$pathSeparator$folderName.barrel.dart';

    if (!context.excluded(barrelPath) && folderContext.isNotEmpty) {
      BarrelWriterProcessor(path: barrelPath, data: data).process();
    }

    if (folderContext.folders.isNotEmpty) {
      for (final folder in folderContext.folders) {
        _exploreFolder(folder, context);
      }
    }
  }

  String get _rootFolder => Directory.current.path;

  String _getSrcFolder(String fullName) {
    final projectDirectory = Directory.current.path;

    final filePieces = fullName.split(pathSeparator);
    final fileDirectory =
        filePieces.sublist(2, filePieces.length - 1).join(pathSeparator);

    return '$projectDirectory$pathSeparator$fileDirectory';
  }

  BarrelContext _getContext(ConstantReader annotation, String rootFolder) {
    final paths = annotation
        .read('exclude')
        .listValue
        .map((exclusion) => '$rootFolder/${exclusion.toStringValue()}')
        .toList(growable: false);

    return BarrelContext(exclusions: paths);
  }
}
