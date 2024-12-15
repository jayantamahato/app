import 'package:flutter_webrtc/flutter_webrtc.dart';

class WrtService {
  Future<RTCPeerConnection> setUpPeerConnection() async {
    return await createPeerConnection({
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ],
    });
  }

  Future<String> createOffer(RTCPeerConnection peerConnection) async {
    try {
      RTCSessionDescription offer = await peerConnection.createOffer(
        {
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': true,
        },
      );
      await peerConnection.setLocalDescription(offer);
      return offer.sdp!;
    } catch (e) {
      return "Error while creating offer";
    }
  }

  Future<String> createAnswer(RTCPeerConnection peerConnection) async {
    RTCSessionDescription answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);
    return answer.sdp!;
  }
}
