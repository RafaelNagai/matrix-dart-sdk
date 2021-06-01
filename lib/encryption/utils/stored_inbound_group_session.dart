/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2021 Famedly GmbH
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

class StoredInboundGroupSession {
  final int clientId;
  final String roomId;
  final String sessionId;
  final String pickle;
  final String content;
  final String indexes;
  final String allowedAtIndex;
  final bool uploaded;
  final String senderKey;
  final String senderClaimedKeys;

  StoredInboundGroupSession({
    this.clientId,
    this.roomId,
    this.sessionId,
    this.pickle,
    this.content,
    this.indexes,
    this.allowedAtIndex,
    this.uploaded,
    this.senderKey,
    this.senderClaimedKeys,
  });

  factory StoredInboundGroupSession.fromJson(Map<String, dynamic> json) =>
      StoredInboundGroupSession(
        clientId: json['client_id'],
        roomId: json['room_id'],
        sessionId: json['session_id'],
        pickle: json['pickle'],
        content: json['content'],
        indexes: json['indexes'],
        allowedAtIndex: json['allowed_at_index'],
        uploaded: json['uploaded'],
        senderKey: json['sender_key'],
        senderClaimedKeys: json['sender_claimed_keys'],
      );

  Map<String, dynamic> toJson() => {
        'client_id': clientId,
        'room_id': roomId,
        'session_id': sessionId,
        'pickle': pickle,
        'content': content,
        'indexes': indexes,
        'allowed_at_index': allowedAtIndex,
        'uploaded': uploaded,
        'sender_key': senderKey,
        'sender_claimed_keys': senderClaimedKeys,
      };
}
