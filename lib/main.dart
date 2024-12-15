import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'publisher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebRTC',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PublisherScreen(),
    );
  }
}

class LiveStreamPage extends StatefulWidget {
  @override
  _LiveStreamPageState createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  late IO.Socket socket;
  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;
  late MediaStream _localStream;
  late RTCPeerConnection _peerConnection;

  bool isProducer = false;
  bool isSubscriber = false;
  String? roomId = 'room123'; // Example roomId

  @override
  void initState() {
    super.initState();
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
    _initSocket();
    _initWebRTC();
  }

  // Initialize Socket.IO
  void _initSocket() {
    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.on('connect', (_) {
      print('Connected to server');
      socket.emit('joinRoom', roomId);
    });

    socket.on('new-producer', (data) {
      // Handle new producer (when someone else starts streaming)
      if (data['socketId'] != socket.id) {
        _consume(data['producerId']);
      }
    });

    socket.on('new-consumer', (data) {
      // Handle new consumer joining (this can be used for peer-to-peer interactions)
      print('New consumer: ${data['socketId']}');
    });

    socket.on('user-left', (socketId) {
      // Handle user left
      print('$socketId left the room');
    });
  }

  // Initialize WebRTC components (local and remote renderers)
  void _initWebRTC() async {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    // Access local media (camera/microphone)
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    _localRenderer.srcObject = _localStream;
  }

  // Get local media stream (camera and microphone)
  Future<MediaStream> _getUserMedia() async {
    final constraints = {
      'audio': true,
      'video': true,
    };

    return await navigator.mediaDevices.getUserMedia(constraints);
  }

  // Start producing (sending media)
  void _startProducing() async {
    isProducer = true;

    // Create a peer connection (offer to connect)
    _peerConnection = await createPeerConnection(
      {
        'iceServers': [
          {
            'urls': 'stun:stun.l.google.com:19302',
          },
        ],
      },
    );

    // Add the local stream to the peer connection
    _peerConnection.addStream(_localStream);

    // Handle ice candidate events
    _peerConnection.onIceCandidate = (candidate) {
      if (candidate != null) {
        socket.emit('new-ice-candidate', candidate);
      }
    };

    // Create offer to send to server
    RTCSessionDescription offer = await _peerConnection.createOffer();
    await _peerConnection.setLocalDescription(offer);

    // Send offer to the server
    socket.emit('produce', {
      'roomId': roomId,
      'kind': 'video', // Change to 'audio' for audio-only stream
      'rtpParameters': offer.sdp,
    });
  }

  // Start consuming (watching another user's stream)
  void _consume(String producerId) async {
    // Create a new transport for consuming
    RTCSessionDescription answer = await _peerConnection.createAnswer();
    await _peerConnection.setLocalDescription(answer);

    socket.emit('consume', {
      'roomId': roomId,
      'producerId': producerId,
    });

    // Attach the remote stream to the renderer
    _peerConnection.onAddStream = (stream) {
      _remoteRenderer.srcObject = stream;
    };
  }

  // Disconnect the connection
  void _disconnect() async {
    await _peerConnection.close();
    socket.disconnect();
    _localRenderer.srcObject?.dispose();
    _remoteRenderer.srcObject?.dispose();
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Streaming')),
      body: Column(
        children: [
          Expanded(
            child: RTCVideoView(_localRenderer),
          ),
          Expanded(
            child: RTCVideoView(_remoteRenderer),
          ),
          ElevatedButton(
            onPressed: isProducer ? null : _startProducing,
            child: Text('Start Producing'),
          ),
          ElevatedButton(
            onPressed: isSubscriber
                ? null
                : () => _consume('producerId'), // Example producerId
            child: Text('Start Consuming'),
          ),
        ],
      ),
    );
  }
}
