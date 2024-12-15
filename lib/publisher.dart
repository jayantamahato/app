import 'dart:developer';

import 'package:app/socket.dart';
import 'package:app/wrt_service.dart';
import 'package:flutter/material.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'media_soup.dart';

class PublisherScreen extends StatefulWidget {
  const PublisherScreen({super.key});

  @override
  State<PublisherScreen> createState() => _PublisherScreenState();
}

class _PublisherScreenState extends State<PublisherScreen> {
  String streamId = 'STRM0098';
  String roomId = 'RM852';

  late final RTCPeerConnection? _peerConnection;
  late final MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  Map<String, dynamic> routerRtpCapabilities = {};
  MediaSoupService _mediaSoupService = MediaSoupService();
  // IO.Socket? socket;
  // final device = Device();
  // Transport? transport;
  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SocketService.init();
      await _localRenderer.initialize();
      _peerConnection = await WrtService().setUpPeerConnection();
      setUpLocalStream();
      setState(() {});
    });
    super.initState();
  }

  void setUpLocalStream() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream);
    });
    _localRenderer.srcObject = _localStream;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Streaming'),
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Center(
          child: RTCVideoView(
            _localRenderer,
            mirror: true,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            placeholderBuilder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(18),
        child: ElevatedButton(
            onPressed: () {
              joinRoom();
            },
            child: const Text('Start')),
      ),
    );
  }

//join room
  void joinRoom() {
    var params = {'roomId': roomId, 'streamId': streamId};
    SocketService.emit(Events.joinRoom, params);
    SocketService.on(Events.joined, (data) {
      onJoinRoom(params);
    });
  }

  void onJoinRoom(data) {
    try {
      // getRouterCapabilities(data);
      SocketService.emit(Events.getRouterCapabilities, data);
      SocketService.on(Events.routerCapabilities, (res) {
        onRouterCapabilities(res);
      });
    } catch (e) {
      debugPrint('**********Error  on join room**********');
      debugPrint('$e');
    }
  }

  Future<void> onRouterCapabilities(data) async {
    try {
      RtpCapabilities rtpCapabilities =
          RtpCapabilities.fromMap(data['routerCapabilities']);

      await _mediaSoupService.load(rtpCapabilities: rtpCapabilities);

      if (!_mediaSoupService.canProduce(
          mediaType: RTCRtpMediaType.RTCRtpMediaTypeVideo)) {
        return;
      }
      var params = {
        'roomId': roomId,
        'streamId': streamId,
        'routerRtpCapabilities':
            _mediaSoupService.device!.rtpCapabilities.toMap(),
        'forceTcp': false,
      };
      SocketService.emit(Events.createProducerTransport, params);
      SocketService.on(Events.transport, (data) {
        onTransport(data);
      });
    } catch (e) {
      debugPrint('**********Error  on router capabilities**********');
      debugPrint('$e');
    }
  }

  void onTransport(data) {
    try {
      _mediaSoupService.createTransport(data: data);
    } catch (e) {
      debugPrint('**********Error  on transport**********');
      debugPrint('$e');
    }
  }
}
