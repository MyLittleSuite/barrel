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

import 'dart:io';

import 'package:barrel_generator/src/contexts/barrel_context.dart';
import 'package:barrel_generator/src/contexts/barrel_folder_context.dart';
import 'package:barrel_generator/src/processors/processor.dart';
import 'package:barrel_generator/src/utils/path.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

/// A processor that collects all the files and folders in a given directory
class BarrelFolderProcessor extends Processor<BarrelFolderContext> {
  final Directory folder;
  final BarrelContext context;

  const BarrelFolderProcessor(this.folder, {required this.context});

  @override
  BarrelFolderContext process() {
    final items = folder.listSync();

    fileConditions(file) =>
        file is File &&
        file.path.endsWith('.dart') &&
        !file.path.endsWith('.barrel.dart') &&
        !context.excluded(file.path);
    folderConditions(folder) =>
        folder is Directory &&
        Glob('${folder.path}/**.dart').listSync().isNotEmpty;
    barrelConditions(file) => !context.excluded(file.path);

    final folders = items
        .where(folderConditions)
        .cast<Directory>()
        .toList(growable: false);
    final barrels = folders
        .map((folder) {
          final folderName = folder.path.split(pathSeparator).last;
          return File('${folder.path}$pathSeparator$folderName.barrel.dart');
        })
        .where(barrelConditions)
        .map((barrel) {
          final barrelPath = barrel.path
              .split(pathSeparator)
              .reversed
              .take(2)
              .toList(growable: false)
              .reversed
              .join('/');
          return "export '$barrelPath';";
        })
        .toList(growable: false);

    final files = items
        .where(fileConditions)
        .map((file) {
          final fileName = file.path.split(pathSeparator).last;
          return "export '$fileName';";
        })
        .toList(growable: false);

    return BarrelFolderContext(
      folders: folders,
      barrels: barrels,
      files: files,
    );
  }
}
