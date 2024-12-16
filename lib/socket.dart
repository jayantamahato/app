import 'dart:developer';

import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static late IO.Socket socket;
  static IO.Socket init() {
    socket = IO.io('http://192.168.1.125:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();
    return socket;
  }

  static void disconnect() {
    socket.disconnect();
  }

  static void emit(String event, dynamic data) {
    !socket.connected ? init() : null;
    socket.off(event);
    socket.emit(event, data);
  }

  static void on(String event, Function(dynamic) callback) {
    // ignore: unnecessary_string_interpolations
    log('$event');
    !socket.connected ? init() : null;
    socket.off(event);
    socket.on(event, callback);
  }
}

class Events {
  static const joinRoom = 'joinRoom';
  static const joined = 'joined';
  static const getRouterCapabilities = 'getRouterCapabilities';
  static const routerCapabilities = 'routerCapabilities';
  static const createProducerTransport = 'createProducerTransport';
  static const transport = 'transport';
  static const createProducer = 'createProducer';
  static const producer = 'producer';
}
