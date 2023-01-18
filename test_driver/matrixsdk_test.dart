/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2019, 2020, 2021 Famedly GmbH
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as
 *   published by the Free Software Foundation, either version 3 of the
 *   License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:io';

import 'package:hive/hive.dart';
import 'package:olm/olm.dart' as olm;
import 'package:test/test.dart';

import 'package:matrix/matrix.dart';
import '../test/fake_database.dart';
import 'test_config.dart';

const String testMessage = 'Hello world';
const String testMessage2 = 'Hello moon';
const String testMessage3 = 'Hello sun';
const String testMessage4 = 'Hello star';
const String testMessage5 = 'Hello earth';
const String testMessage6 = 'Hello mars';

void main() => group('Integration tests', () {
      test('E2EE', () async {
        Client? testClientA, testClientB;

        try {
          Hive.init(null);

          await olm.init();
          olm.Account();
          Logs().i('[LibOlm] Enabled');

          Logs().i('++++ Login Alice at ++++');
          testClientA = Client('TestClientA', databaseBuilder: getDatabase);
          await testClientA.checkHomeserver(Uri.parse(TestUser.homeserver));
          await testClientA.login(LoginType.mLoginPassword,
              identifier: AuthenticationUserIdentifier(
                  user: TestUser.username.localpart!),
              password: TestUser.password);
          expect(testClientA.encryptionEnabled, true);

          Logs().i('++++ Login Bob ++++');
          testClientB = Client('TestClientB', databaseBuilder: getDatabase);
          await testClientB.checkHomeserver(Uri.parse(TestUser.homeserver));
          await testClientB.login(LoginType.mLoginPassword,
              identifier: AuthenticationUserIdentifier(
                  user: TestUser.username2.localpart!),
              password: TestUser.password2);
          expect(testClientB.encryptionEnabled, true);

          Logs().i('++++ (Alice) Leave all rooms ++++');
          while (testClientA.rooms.isNotEmpty) {
            final room = testClientA.rooms.first;
            if (room.canonicalAlias.isNotEmpty) {
              break;
            }
            try {
              await room.leave();
              await room.forget();
            } catch (_) {}
          }

          Logs().i('++++ (Bob) Leave all rooms ++++');
          for (var i = 0; i < 3; i++) {
            if (testClientB.rooms.isNotEmpty) {
              final room = testClientB.rooms.first;
              try {
                await room.leave();
                await room.forget();
              } catch (_) {}
            }
          }

          Logs().i('++++ Check if own olm device is verified by default ++++');
          expect(testClientA.userDeviceKeys, contains(TestUser.username));
          expect(testClientA.userDeviceKeys[TestUser.username]!.deviceKeys,
              contains(testClientA.deviceID));
          expect(
              testClientA.userDeviceKeys[TestUser.username]!
                  .deviceKeys[testClientA.deviceID!]!.verified,
              isTrue);
          expect(
              !testClientA.userDeviceKeys[TestUser.username]!
                  .deviceKeys[testClientA.deviceID!]!.blocked,
              isTrue);
          expect(testClientB.userDeviceKeys, contains(TestUser.username2));
          expect(testClientB.userDeviceKeys[TestUser.username2]!.deviceKeys,
              contains(testClientB.deviceID));
          expect(
              testClientB.userDeviceKeys[TestUser.username2]!
                  .deviceKeys[testClientB.deviceID!]!.verified,
              isTrue);
          expect(
              !testClientB.userDeviceKeys[TestUser.username2]!
                  .deviceKeys[testClientB.deviceID!]!.blocked,
              isTrue);

          Logs().i('++++ (Alice) Create room and invite Bob ++++');
          await testClientA.startDirectChat(
            TestUser.username2,
            enableEncryption: false,
          );
          await Future.delayed(Duration(seconds: 1));
          final room = testClientA.rooms.first;
          final roomId = room.id;

          Logs().i('++++ (Bob) Join room ++++');
          final inviteRoom = testClientB.getRoomById(roomId)!;
          await inviteRoom.join();
          await Future.delayed(Duration(seconds: 1));
          expect(inviteRoom.membership, Membership.join);

          Logs().i('++++ (Alice) Enable encryption ++++');
          expect(room.encrypted, false);
          await room.enableEncryption();
          await Future.delayed(Duration(seconds: 5));
          expect(room.encrypted, isTrue);
          expect(
              room.client.encryption!.keyManager
                  .getOutboundGroupSession(room.id),
              null);

          Logs().i('++++ (Alice) Check known olm devices ++++');
          expect(testClientA.userDeviceKeys, contains(TestUser.username2));
          expect(testClientA.userDeviceKeys[TestUser.username2]!.deviceKeys,
              contains(testClientB.deviceID));
          expect(
              testClientA.userDeviceKeys[TestUser.username2]!
                  .deviceKeys[testClientB.deviceID!]!.verified,
              isFalse);
          expect(
              testClientA.userDeviceKeys[TestUser.username2]!
                  .deviceKeys[testClientB.deviceID!]!.blocked,
              isFalse);
          expect(testClientB.userDeviceKeys, contains(TestUser.username));
          expect(testClientB.userDeviceKeys[TestUser.username]!.deviceKeys,
              contains(testClientA.deviceID));
          expect(
              testClientB.userDeviceKeys[TestUser.username]!
                  .deviceKeys[testClientA.deviceID!]!.verified,
              isFalse);
          expect(
              testClientB.userDeviceKeys[TestUser.username]!
                  .deviceKeys[testClientA.deviceID!]!.blocked,
              isFalse);
          await Future.wait([
            testClientA.updateUserDeviceKeys(),
            testClientB.updateUserDeviceKeys(),
          ]);
          await testClientA.userDeviceKeys[TestUser.username2]!
              .deviceKeys[testClientB.deviceID!]!
              .setVerified(true);

          Logs().i('++++ Check if own olm device is verified by default ++++');
          expect(testClientA.userDeviceKeys, contains(TestUser.username));
          expect(testClientA.userDeviceKeys[TestUser.username]!.deviceKeys,
              contains(testClientA.deviceID));
          expect(
              testClientA.userDeviceKeys[TestUser.username]!
                  .deviceKeys[testClientA.deviceID!]!.verified,
              isTrue);
          expect(testClientB.userDeviceKeys, contains(TestUser.username2));
          expect(testClientB.userDeviceKeys[TestUser.username2]!.deviceKeys,
              contains(testClientB.deviceID));
          expect(
              testClientB.userDeviceKeys[TestUser.username2]!
                  .deviceKeys[testClientB.deviceID!]!.verified,
              isTrue);

          Logs().i("++++ (Alice) Send encrypted message: '$testMessage' ++++");
          await room.sendTextEvent(testMessage);
          await Future.delayed(Duration(seconds: 5));
          expect(
              room.client.encryption!.keyManager
                  .getOutboundGroupSession(room.id),
              isNotNull);
          var currentSessionIdA = room.client.encryption!.keyManager
              .getOutboundGroupSession(room.id)!
              .outboundGroupSession!
              .session_id();
          /*expect(room.client.encryption.keyManager
          .getInboundGroupSession(room.id, currentSessionIdA, '') !=
      null);*/
          if (Platform.environment['HOMESERVER'] != 'dendrite') {
            expect(
                testClientA.encryption!.olmManager
                    .olmSessions[testClientB.identityKey]!.length,
                1);
            expect(
                testClientB.encryption!.olmManager
                    .olmSessions[testClientA.identityKey]!.length,
                1);
            expect(
                testClientA.encryption!.olmManager
                    .olmSessions[testClientB.identityKey]!.first.sessionId,
                testClientB.encryption!.olmManager
                    .olmSessions[testClientA.identityKey]!.first.sessionId);
          }

          /*expect(inviteRoom.client.encryption.keyManager
          .getInboundGroupSession(inviteRoom.id, currentSessionIdA, '') !=
      null);*/
          expect(room.lastEvent!.body, testMessage);
          expect(inviteRoom.lastEvent!.body, testMessage);
          Logs().i(
              "++++ (Bob) Received decrypted message: '${inviteRoom.lastEvent!.body}' ++++");

          Logs().i(
              "++++ (Alice) Send again encrypted message: '$testMessage2' ++++");
          await room.sendTextEvent(testMessage2);
          await Future.delayed(Duration(seconds: 5));
          expect(
              testClientA.encryption!.olmManager
                  .olmSessions[testClientB.identityKey]!.length,
              1);
          expect(
              testClientB.encryption!.olmManager
                  .olmSessions[testClientA.identityKey]!.length,
              1);
          expect(
              testClientA.encryption!.olmManager
                  .olmSessions[testClientB.identityKey]!.first.sessionId,
              testClientB.encryption!.olmManager
                  .olmSessions[testClientA.identityKey]!.first.sessionId);

          expect(
              room.client.encryption!.keyManager
                  .getOutboundGroupSession(room.id)!
                  .outboundGroupSession!
                  .session_id(),
              currentSessionIdA);
          /*expect(room.client.encryption.keyManager
          .getInboundGroupSession(room.id, currentSessionIdA, '') !=
      null);*/
          expect(room.lastEvent!.body, testMessage2);
          expect(inviteRoom.lastEvent!.body, testMessage2);
          Logs().i(
              "++++ (Bob) Received decrypted message: '${inviteRoom.lastEvent!.body}' ++++");

          Logs().i(
              "++++ (Bob) Send again encrypted message: '$testMessage3' ++++");
          await inviteRoom.sendTextEvent(testMessage3);
          await Future.delayed(Duration(seconds: 5));
          expect(
              testClientA.encryption!.olmManager
                  .olmSessions[testClientB.identityKey]!.length,
              1);
          expect(
              testClientB.encryption!.olmManager
                  .olmSessions[testClientA.identityKey]!.length,
              1);
          expect(
              room.client.encryption!.keyManager
                  .getOutboundGroupSession(room.id)!
                  .outboundGroupSession!
                  .session_id(),
              currentSessionIdA);
          final inviteRoomOutboundGroupSession = inviteRoom
              .client.encryption!.keyManager
              .getOutboundGroupSession(inviteRoom.id)!;

          expect(inviteRoomOutboundGroupSession.isValid, isTrue);
          /*expect(inviteRoom.client.encryption.keyManager.getInboundGroupSession(
          inviteRoom.id,
          inviteRoomOutboundGroupSession.outboundGroupSession.session_id(),
          '') !=
      null);
  expect(room.client.encryption.keyManager.getInboundGroupSession(
          room.id,
          inviteRoomOutboundGroupSession.outboundGroupSession.session_id(),
          '') !=
      null);*/
          expect(inviteRoom.lastEvent!.body, testMessage3);
          expect(room.lastEvent!.body, testMessage3);
          Logs().i(
              "++++ (Alice) Received decrypted message: '${room.lastEvent!.body}' ++++");

          Logs().i('++++ Login Bob in another client ++++');
          final testClientC =
              Client('TestClientC', databaseBuilder: getDatabase);
          await testClientC.checkHomeserver(Uri.parse(TestUser.homeserver));
          // We can't sign in using the displayname, since that breaks e2ee on dendrite: https://github.com/matrix-org/dendrite/issues/2914
          await testClientC.login(LoginType.mLoginPassword,
              identifier: AuthenticationUserIdentifier(
                  user: TestUser.username2.localpart!),
              password: TestUser.password2);
          await Future.delayed(Duration(seconds: 3));

          Logs().i(
              "++++ (Alice) Send again encrypted message: '$testMessage4' ++++");
          await room.sendTextEvent(testMessage4);
          await Future.delayed(Duration(seconds: 5));
          expect(
              testClientA.encryption!.olmManager
                  .olmSessions[testClientB.identityKey]!.length,
              1);
          expect(
              testClientB.encryption!.olmManager
                  .olmSessions[testClientA.identityKey]!.length,
              1);
          expect(
              testClientA.encryption!.olmManager
                  .olmSessions[testClientB.identityKey]!.first.sessionId,
              testClientB.encryption!.olmManager
                  .olmSessions[testClientA.identityKey]!.first.sessionId);
          expect(
              testClientA.encryption!.olmManager
                  .olmSessions[testClientC.identityKey]!.length,
              1);
          expect(
              testClientC.encryption!.olmManager
                  .olmSessions[testClientA.identityKey]!.length,
              1);
          expect(
              testClientA.encryption!.olmManager
                  .olmSessions[testClientC.identityKey]!.first.sessionId,
              testClientC.encryption!.olmManager
                  .olmSessions[testClientA.identityKey]!.first.sessionId);
          expect(
              room.client.encryption!.keyManager
                  .getOutboundGroupSession(room.id)!
                  .outboundGroupSession!
                  .session_id(),
              currentSessionIdA);
          /*expect(inviteRoom.client.encryption.keyManager
          .getInboundGroupSession(inviteRoom.id, currentSessionIdA, '') !=
      null);*/
          expect(room.lastEvent!.body, testMessage4);
          expect(inviteRoom.lastEvent!.body, testMessage4);
          Logs().i(
              "++++ (Bob) Received decrypted message: '${inviteRoom.lastEvent!.body}' ++++");

          Logs()
              .i('++++ Logout Bob another client ${testClientC.deviceID} ++++');
          await testClientC.dispose(closeDatabase: false);
          await testClientC.logout();
          await Future.delayed(Duration(seconds: 5));

          Logs().i(
              "++++ (Alice) Send again encrypted message: '$testMessage6' ++++");
          await room.sendTextEvent(testMessage6);
          await Future.delayed(Duration(seconds: 5));
          expect(
              testClientA.encryption!.olmManager
                  .olmSessions[testClientB.identityKey]!.length,
              1);
          expect(
              testClientB.encryption!.olmManager
                  .olmSessions[testClientA.identityKey]!.length,
              1);
          expect(
              testClientA.encryption!.olmManager
                  .olmSessions[testClientB.identityKey]!.first.sessionId,
              testClientB.encryption!.olmManager
                  .olmSessions[testClientA.identityKey]!.first.sessionId);

          // This does not work on conduit because of a server bug: https://gitlab.com/famedly/conduit/-/issues/325
          if (Platform.environment['HOMESERVER'] != 'conduit') {
            expect(
                room.client.encryption!.keyManager
                    .getOutboundGroupSession(room.id)!
                    .outboundGroupSession!
                    .session_id(),
                isNot(currentSessionIdA));
          }
          currentSessionIdA = room.client.encryption!.keyManager
              .getOutboundGroupSession(room.id)!
              .outboundGroupSession!
              .session_id();
          /*expect(inviteRoom.client.encryption.keyManager
          .getInboundGroupSession(inviteRoom.id, currentSessionIdA, '') !=
      null);*/
          expect(room.lastEvent!.body, testMessage6);
          expect(inviteRoom.lastEvent!.body, testMessage6);
          Logs().i(
              "++++ (Bob) Received decrypted message: '${inviteRoom.lastEvent!.body}' ++++");

          await room.leave();
          await room.forget();
          await inviteRoom.leave();
          await inviteRoom.forget();
          await Future.delayed(Duration(seconds: 1));
        } catch (e, s) {
          Logs().e('Test failed', e, s);
          rethrow;
        } finally {
          Logs().i('++++ Logout Alice and Bob ++++');
          if (testClientA?.isLogged() ?? false) await testClientA!.logoutAll();
          if (testClientA?.isLogged() ?? false) await testClientB!.logoutAll();
          await testClientA?.dispose(closeDatabase: false);
          await testClientB?.dispose(closeDatabase: false);
          testClientA = null;
          testClientB = null;
        }
        return;
      });
    }, timeout: Timeout(Duration(minutes: 6)));
