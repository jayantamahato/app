import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';

class MediaSoupService {
  Device? device = Device();
  Transport? producerTransport;
  Future<void> load({required RtpCapabilities rtpCapabilities}) async {
    try {
      debugPrint('${rtpCapabilities.codecs[0].toMap()}');
      // debugPrint('${rtpCapabilities.fecMechanisms}');
      // debugPrint('${rtpCapabilities.headerExtensions}');
      await device!.load(routerRtpCapabilities: rtpCapabilities);
    } catch (e) {
      debugPrint('**********Error  device loading**********');
      debugPrint('$e');
    }
  }

  bool canProduce({required RTCRtpMediaType mediaType}) {
    try {
      return device!.canProduce(mediaType);
    } catch (e) {
      debugPrint('**********Error  device check **********');
      debugPrint('$e');
      return false;
    }
  }

  Future<void> createTransport({required Map data}) async {
    try {
      List<IceCandidate> iceCandidates = [];
      String id = data['id'];
      DtlsParameters dtlsParameters =
          DtlsParameters.fromMap(data['dtlsParameters']);
      IceParameters iceParameters =
          IceParameters.fromMap(data['iceParameters']);
      data['iceCandidates'].forEach((element) {
        iceCandidates.add(IceCandidate.fromMap(element));
      });
      log('$data');

      // Create a transport.
      producerTransport = device!.createSendTransport(
          id: id,
          dtlsParameters: dtlsParameters,
          iceParameters: iceParameters,
          iceCandidates: iceCandidates);
      log('transport created');

      producerTransport!.on('connect', (data) {
        log('$data');
      });
      producerTransport!.on('produce', (data) {
        log('$data');
      });
      producerTransport!.on('connectionstatechange', (state) {
        log('$data');
      });

      // Transport transport = device.createSendTransportFromMap(data);
    } catch (e) {
      debugPrint('**********Error createTransport**********');
      debugPrint('$e');
    }
  }
}
