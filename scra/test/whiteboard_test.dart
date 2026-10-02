import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/models/user_model.dart';
import 'package:smart_class/models/whiteboard_model.dart';
import 'package:smart_class/services/webrtc/signaling_service.dart';

import 'fakes/fake_realtime.dart';
import 'fakes/mock_data_store.dart';
import 'helpers/test_app.dart';

void main() {
  group('Whiteboard model', () {
    test('applies board operations like the server does', () {
      final board = Whiteboard();
      expect(board.apply({'type': 'board', 'op': 'show'}), isTrue);
      expect(board.active, isTrue);
      board.apply({
        'type': 'board',
        'op': 'begin',
        'id': 's1',
        'color': 0xFFFFFFFF,
        'width': 0.01,
        'points': [
          [0.1, 0.2],
        ],
      });
      board.apply({
        'type': 'board',
        'op': 'extend',
        'id': 's1',
        'points': [
          [0.3, 0.4],
        ],
      });
      expect(board.strokes.single.points, [
        const Offset(0.1, 0.2),
        const Offset(0.3, 0.4),
      ]);
      board.apply({'type': 'board', 'op': 'undo'});
      expect(board.strokes, isEmpty);
      expect(board.apply({'type': 'board', 'op': 'nonsense'}), isFalse);
      board.apply({'type': 'board', 'op': 'hide'});
      expect(board.active, isFalse);
    });

    test('board_state replaces the whole board (late joiners)', () {
      final board = Whiteboard()
        ..apply({
          'type': 'board_state',
          'active': true,
          'strokes': [
            {
              'id': 'a',
              'color': 1,
              'width': 0.02,
              'points': [
                [0.5, 0.5],
                [0.6, 0.6],
              ],
            },
            {'id': 'broken'},
          ],
        });
      expect(board.active, isTrue);
      expect(board.strokes.single.id, 'a');
      expect(board.strokes.single.points.length, 2);
    });

    test('points are clamped and rounded when encoded', () {
      expect(Whiteboard.encodePoints([const Offset(1.5, 0.123456)]), [
        [1.0, 0.1235],
      ]);
    });
  });

  test('signaling routes board messages to onBoard', () {
    final signaling = SignalingService(
      roomId: '1',
      userId: '2',
      serverUrl: 'ws://localhost',
    );
    final received = <Map<String, dynamic>>[];
    signaling.onBoard = received.add;
    signaling.handleMessage(jsonEncode({'type': 'board', 'op': 'show'}));
    signaling.handleMessage(
      jsonEncode({'type': 'board_state', 'active': false, 'strokes': []}),
    );
    expect(received.map((m) => m['type']), ['board', 'board_state']);
  });

  testWidgets('lecturer drawing on the whiteboard is sent to the class', (
    tester,
  ) async {
    final deps = await pumpApp(
      tester,
      deps: testDependencies(store: onboardedStore()),
    );
    await signInAs(tester, UserRole.lecturer);
    final media = deps.webRTCService as MockWebRTCService;

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed(
          RouteNames.whiteboard,
          arguments: MockDataStore.liveSessionId,
        );
    await pumpFrames(tester, 12);
    expect(media.sentBoard.first, {'op': 'show'});

    await tester.drag(
      find.byKey(const Key('whiteboard_canvas')),
      const Offset(120, 40),
    );
    await pumpFrames(tester, 4);
    final ops = media.sentBoard.map((m) => m['op']).toList();
    expect(ops, containsAllInOrder(['show', 'begin', 'extend']));
    final begin = media.sentBoard.firstWhere((m) => m['op'] == 'begin');
    final point = (begin['points'] as List).single as List;
    expect(point.every((v) => (v as double) >= 0 && v <= 1), isTrue);

    await tester.tap(find.byTooltip('Clear board'));
    await pumpFrames(tester, 2);
    expect(media.sentBoard.last, {'op': 'clear'});

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await pumpFrames(tester, 6);
    expect(media.sentBoard.last, {'op': 'hide'});
  });

  testWidgets('sharing the screen hides the board so students see the screen', (
    tester,
  ) async {
    final deps = await pumpApp(
      tester,
      deps: testDependencies(store: onboardedStore()),
    );
    await signInAs(tester, UserRole.lecturer);
    final media = deps.webRTCService as MockWebRTCService;
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed(
          RouteNames.whiteboard,
          arguments: MockDataStore.liveSessionId,
        );
    await pumpFrames(tester, 12);
    expect(media.sentBoard.last, {'op': 'show'});

    await tapVisible(tester, find.text('Share Screen'));
    await pumpFrames(tester, 6);
    expect(media.state.screenSharing, isTrue);
    expect(media.sentBoard, contains(equals({'op': 'screen', 'on': true})));
    expect(media.sentBoard.last, {'op': 'hide'});
    expect(
      find.textContaining('Students now see your shared screen'),
      findsOneWidget,
    );

    await tapVisible(tester, find.text('Stop Share'));
    await pumpFrames(tester, 6);
    expect(media.sentBoard.last, {'op': 'show'});
  });

  testWidgets('students see the lecturer whiteboard live', (tester) async {
    final deps = await pumpApp(
      tester,
      deps: testDependencies(store: onboardedStore()),
    );
    await signInAs(tester, UserRole.student);
    final media = deps.webRTCService as MockWebRTCService;

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed(
          RouteNames.studentLiveClassroom,
          arguments: MockDataStore.liveSessionId,
        );
    await pumpFrames(tester, 12);
    expect(find.byKey(const Key('student_whiteboard')), findsNothing);

    media.receiveBoard({'type': 'board', 'op': 'show'});
    media.receiveBoard({
      'type': 'board',
      'op': 'begin',
      'id': 's1',
      'color': 0xFFFFFFFF,
      'width': 0.01,
      'points': [
        [0.2, 0.2],
      ],
    });
    await pumpFrames(tester, 4);
    expect(find.byKey(const Key('student_whiteboard')), findsOneWidget);
    expect(find.text('Whiteboard'), findsOneWidget);

    media.receiveBoard({'type': 'board', 'op': 'hide'});
    await pumpFrames(tester, 4);
    expect(find.byKey(const Key('student_whiteboard')), findsNothing);

    // Lecturer shares the screen: students switch to the shared-screen view.
    media.receiveBoard({'type': 'board', 'op': 'screen', 'on': true});
    await pumpFrames(tester, 4);
    expect(find.text('Screen share'), findsOneWidget);
    expect(find.byKey(const Key('student_screen_waiting')), findsOneWidget);
    media.receiveBoard({'type': 'board', 'op': 'screen', 'on': false});
    await pumpFrames(tester, 4);
    expect(find.byKey(const Key('student_screen_waiting')), findsNothing);
  });
}
