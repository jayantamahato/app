// subscriber.dart (Subscriber's side)
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SubscriberScreen extends StatefulWidget {
  const SubscriberScreen({super.key});

  @override
  _SubscriberScreenState createState() => _SubscriberScreenState();
}

@override
class _SubscriberScreenState extends State<SubscriberScreen> {
  late IO.Socket socket; // Socket connection to the server
  final List<MediaStream> _remoteStreams = []; // List to hold incoming streams
  late RTCPeerConnection
      _peerConnection; // WebRTC peer connection for the subscriber

  final Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls':
            'stun:stun.l.google.com:19302', // Free STUN server provided by Google
      }
    ],
  };

  @override
  void initState() {
    super.initState();
    socket = IO.io(
        'http://localhost:3000',
        IO.OptionBuilder()
            .setTransports(['websocket']).build()); // Connect to the server
    socket.connect();

    // Once connected to the server, emit 'join' to notify the server we're a viewer
    socket.on('connect', (_) {
      print('Connected to server');
      socket.emit('join');
    });

    // Once the consumer (stream viewer) is created, subscribe to the stream
    socket.on('consumer-created', (data) {
      _createSubscriberPeerConnection(data);
    });
  }

  // Function to create WebRTC connection for the subscriber
  Future<void> _createSubscriberPeerConnection(data) async {
    _peerConnection = await createPeerConnection(
        configuration); // Create WebRTC peer connection

    // Handle the incoming stream and display it
    _peerConnection.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'video') {
        setState(() {
          _remoteStreams
              .add(event.streams[0]); // Add the incoming stream to the list
        });
      }
    };

    RTCSessionDescription offer =
        RTCSessionDescription(data['stream'], 'offer');
    await _peerConnection.setRemoteDescription(offer); // Set the incoming offer
    RTCSessionDescription answer =
        await _peerConnection.createAnswer(); // Create answer for the offer
    await _peerConnection
        .setLocalDescription(answer); // Set the answer as local description

    socket.emit('consume', {
      'consumerTransportOptions': data['stream'],
      'producerId':
          data['producerId'], // Send the producer ID to consume the stream
    });
  }

  @override
  void dispose() {
    socket.disconnect(); // Disconnect from the server
    _peerConnection.close(); // Close the WebRTC connection
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Publisher Screen')),
      body: Center(child: Text('Streaming your media...')),
    );
  }
}
