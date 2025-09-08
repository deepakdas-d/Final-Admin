// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

RTCPeerConnection? _peerConnection;

Future<void> listenToUser() async {
  // Create peer connection
  _peerConnection = await createPeerConnection({
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
  });

  // Listen for remote stream
  _peerConnection!.onTrack = (event) {
    // Play the incoming stream
    // Use RTCVideoRenderer or just audio
    final stream = event.streams.first;
    // play stream audio here
  };

  // Get offer from user
  DocumentSnapshot doc = await FirebaseFirestore.instance
      .collection('calls')
      .doc('live-call')
      .get();
  final offer = doc['offer'];
  await _peerConnection!.setRemoteDescription(
    RTCSessionDescription(offer['sdp'], offer['type']),
  );

  // Create answer
  RTCSessionDescription answer = await _peerConnection!.createAnswer();
  await _peerConnection!.setLocalDescription(answer);

  // Send answer back to user
  await FirebaseFirestore.instance.collection('calls').doc('live-call').update({
    'answer': answer.toMap(),
  });

  // Handle ICE candidates (optional)
}
