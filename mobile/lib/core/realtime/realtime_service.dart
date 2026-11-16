import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../network/api_config.dart';
import '../network/token_storage_service.dart';

class RealtimeEvent {
  const RealtimeEvent(this.name, this.data, {this.role});

  final String name;
  final Map<String, dynamic> data;
  final String? role;
}

class RealtimeService {
  RealtimeService({required TokenStorageService tokenStorage})
    : _tokenStorage = tokenStorage;

  static const _eventNames = [
    'coursePublished',
    'courseUpdated',
    'courseUnpublished',
    'registrationCreated',
    'registrationConfirmed',
    'registrationRejected',
    'paymentSubmitted',
    'seatAvailabilityUpdated',
    'seatHoldExpired',
  ];

  final TokenStorageService _tokenStorage;
  final StreamController<RealtimeEvent> _events =
      StreamController<RealtimeEvent>.broadcast();

  socket_io.Socket? _socket;
  String? _token;
  String? _role;
  int _generation = 0;
  int _connectRequest = 0;

  Stream<RealtimeEvent> get events => _events.stream;

  Future<void> connect({required String role}) async {
    _role = role;
    final connectRequest = ++_connectRequest;
    final token = await _tokenStorage.readToken();

    if (connectRequest != _connectRequest) return;
    if (token == null || token.isEmpty) {
      disconnect();
      return;
    }

    if (_socket != null && _token == token) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }

    final generation = ++_generation;
    _closeSocket();
    _token = token;

    final socket = socket_io.io(ApiConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'auth': {'token': token},
    });
    _socket = socket;

    socket.on('connect', (_) {
      if (generation == _generation) {
        _events.add(RealtimeEvent('syncRequired', const {}, role: role));
      }
    });

    for (final eventName in _eventNames) {
      socket.on(eventName, (dynamic payload) {
        if (generation == _generation) {
          _events.add(RealtimeEvent(eventName, _asMap(payload), role: _role));
        }
      });
    }

    socket.on('connect_error', (dynamic error) {
      debugPrint('Realtime connection failed: $error');
    });
    socket.connect();
  }

  void onAppResumed() {
    final role = _role;
    if (role == null) return;

    if (_socket?.connected ?? false) {
      _events.add(RealtimeEvent('syncRequired', const {}, role: role));
    } else {
      unawaited(connect(role: role));
    }
  }

  void disconnect() {
    _connectRequest++;
    _generation++;
    _role = null;
    _token = null;
    _closeSocket();
  }

  Future<void> dispose() async {
    disconnect();
    await _events.close();
  }

  void _closeSocket() {
    final socket = _socket;
    _socket = null;
    socket?.dispose();
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}
