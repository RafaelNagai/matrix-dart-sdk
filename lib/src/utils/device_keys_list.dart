import 'dart:convert';

import '../client.dart';

class DeviceKeysList {
  String userId;
  bool outdated = true;
  Map<String, DeviceKeys> deviceKeys = {};

  DeviceKeysList.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    outdated = json['outdated'];
    deviceKeys = {};
    for (final rawDeviceKeyEntry in json['device_keys'].entries) {
      deviceKeys[rawDeviceKeyEntry.key] =
          DeviceKeys.fromJson(rawDeviceKeyEntry.value);
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    final data = map;
    data['user_id'] = userId;
    data['outdated'] = outdated ?? true;

    var rawDeviceKeys = <String, dynamic>{};
    for (final deviceKeyEntry in deviceKeys.entries) {
      rawDeviceKeys[deviceKeyEntry.key] = deviceKeyEntry.value.toJson();
    }
    data['device_keys'] = rawDeviceKeys;
    return data;
  }

  @override
  String toString() => json.encode(toJson());

  DeviceKeysList(this.userId);
}

class DeviceKeys {
  String userId;
  String deviceId;
  List<String> algorithms;
  Map<String, String> keys;
  Map<String, dynamic> signatures;
  Map<String, dynamic> unsigned;
  bool verified;
  bool blocked;

  String get curve25519Key => keys['curve25519:$deviceId'];
  String get ed25519Key => keys['ed25519:$deviceId'];

  Future<void> setVerified(bool newVerified, Client client) {
    verified = newVerified;
    return client.storeAPI.storeUserDeviceKeys(client.userDeviceKeys);
  }

  Future<void> setBlocked(bool newBlocked, Client client) {
    blocked = newBlocked;
    for (var room in client.rooms) {
      if (!room.encrypted) continue;
      if (room.getParticipants().indexWhere((u) => u.id == userId) != -1) {
        room.clearOutboundGroupSession();
      }
    }
    return client.storeAPI.storeUserDeviceKeys(client.userDeviceKeys);
  }

  DeviceKeys({
    this.userId,
    this.deviceId,
    this.algorithms,
    this.keys,
    this.signatures,
    this.unsigned,
    this.verified,
    this.blocked,
  });

  DeviceKeys.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    deviceId = json['device_id'];
    algorithms = json['algorithms'].cast<String>();
    keys = json['keys'] != null ? Map<String, String>.from(json['keys']) : null;
    signatures = json['signatures'] != null
        ? Map<String, dynamic>.from(json['signatures'])
        : null;
    unsigned = json['unsigned'] != null
        ? Map<String, dynamic>.from(json['unsigned'])
        : null;
    verified = json['verified'] ?? false;
    blocked = json['blocked'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['user_id'] = userId;
    data['device_id'] = deviceId;
    data['algorithms'] = algorithms;
    if (keys != null) {
      data['keys'] = keys;
    }
    if (signatures != null) {
      data['signatures'] = signatures;
    }
    if (unsigned != null) {
      data['unsigned'] = unsigned;
    }
    data['verified'] = verified;
    data['blocked'] = blocked;
    return data;
  }
}
