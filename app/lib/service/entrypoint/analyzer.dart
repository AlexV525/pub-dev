// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:gcloud/service_scope.dart';
import 'package:logging/logging.dart';

import '../../analyzer/handlers.dart';
import '../../service/services.dart';
import '../../shared/env_config.dart';
import '../../shared/handler_helpers.dart';
import '../../shared/popularity_storage.dart';
import '../../task/backend.dart';
import '../../tool/neat_task/pub_dev_tasks.dart';

import '_isolate.dart';

final Logger logger = Logger('pub.analyzer');

class AnalyzerCommand extends Command {
  @override
  String get name => 'analyzer';

  @override
  String get description => 'The analyzer service entrypoint.';

  @override
  Future<void> run() async {
    envConfig.checkServiceEnvironment(name);
    await withServices(() async {
      final worker =
          await startWorkerIsolate(logger: logger, entryPoint: _workerMain);
      registerScopeExitCallback(worker.close);
      await runHandler(logger, analyzerServiceHandler);
    });
  }
}

Future _workerMain(EntryMessage message) async {
  message.protocolSendPort.send(ReadyMessage());

  await taskBackend.start();

  setupAnalyzerPeriodicTasks();
  await popularityStorage.start();

  // wait indefinitely
  await Completer().future;
}
