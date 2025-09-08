import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

class AdminAudioListenPage extends StatefulWidget {
  final String userId;

  const AdminAudioListenPage({super.key, required this.userId});

  @override
  State<AdminAudioListenPage> createState() => _AdminAudioListenPageState();
}

class _AdminAudioListenPageState extends State<AdminAudioListenPage>
    with TickerProviderStateMixin {
  RTCPeerConnection? _peerConnection;
  MediaStream? _remoteStream;
  final _firestore = FirebaseFirestore.instance;
  static const _channel = MethodChannel('audio_record_channel');
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isRecording = false;
  bool _isConnected = false;
  String _statusMessage = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Minimal color palette
  static const Color _primaryColor = Color.fromARGB(
    255,
    209,
    52,
    67,
  ); // Blue-600
  static const Color _surfaceColor = Color(0xFFFAFAFA); // Gray-50
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF111827); // Gray-900
  static const Color _textSecondary = Color(0xFF6B7280); // Gray-500
  static const Color _successColor = Color(0xFF10B981); // Emerald-500
  static const Color _errorColor = Color(0xFFEF4444); // Red-500
  static const Color _warningColor = Color(0xFFF59E0B); // Amber-500

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();
    _setupAnimation();
    _setupConnection();
  }

  void _setupAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  Future<void> _setupConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      log("🔌 PeerConnection state: $state");

      final isConnected =
          state == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
      final isDisconnected =
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed;

      if (isConnected) {
        setState(() {
          _isConnected = true;
          _statusMessage = 'Connected';
        });
      } else if (isDisconnected) {
        log("🛑 Connection lost. Stopping playback.");
        setState(() {
          _isConnected = false;
          _remoteStream = null;
          _remoteRenderer.srcObject = null;
          _statusMessage = 'Disconnected';
        });
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      log("📥 Track event received: ${event.track.kind}");

      if (event.track.kind == 'audio') {
        event.track.onEnded = () {
          log("🛑 Audio track ended");
          setState(() {
            _isConnected = false;
            _remoteStream = null;
            _remoteRenderer.srcObject = null;
            _statusMessage = 'Audio ended';
          });
        };

        setState(() {
          _remoteStream = event.streams.first;
          _remoteRenderer.srcObject = _remoteStream;
          _isConnected = true;
          _statusMessage = 'Receiving audio';
        });

        log(
          "🎧 Remote stream has ${_remoteStream!.getAudioTracks().length} audio tracks",
        );
        for (var track in _remoteStream!.getAudioTracks()) {
          log(
            "🔊 Track ID: ${track.id}, Enabled: ${track.enabled}, Muted: ${track.muted}",
          );
        }

        _peerConnection?.getReceivers().then((receivers) {
          for (var receiver in receivers) {
            log(
              "🔍 Receiver: ${receiver.track?.kind}, enabled: ${receiver.track?.enabled}",
            );
          }
        });
      }
    };

    _peerConnection!.onIceCandidate = (candidate) {
      _firestore
          .collection('calls')
          .doc(widget.userId)
          .collection('calleeCandidates')
          .add(candidate.toMap());
    };

    // Read the user's offer
    final roomRef = _firestore.collection('calls').doc(widget.userId);
    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists || roomSnapshot.data()?['offer'] == null) {
      log("❌ No offer found from user.");
      setState(() {
        _statusMessage = 'No audio source found';
      });
      return;
    }

    final offer = roomSnapshot.data()!['offer'];

    await _peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );
    log("✅ Offer set as remote description");

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await roomRef.update({'answer': answer.toMap()});
    log("✅ Sent answer to Firestore");

    setState(() {
      _statusMessage = 'Connecting...';
    });

    // Listen for caller's ICE candidates
    roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        _peerConnection?.addCandidate(
          RTCIceCandidate(
            doc['candidate'],
            doc['sdpMid'],
            doc['sdpMLineIndex'],
          ),
        );
      }
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final micStatus = await Permission.microphone.request();
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    PermissionStatus storageStatus;
    if (Platform.isAndroid && sdkInt >= 33) {
      storageStatus = await Permission.audio.request();
    } else {
      storageStatus = await Permission.storage.request();
    }

    PermissionStatus bluetoothStatus = PermissionStatus.granted;
    if (Platform.isAndroid && sdkInt >= 31) {
      bluetoothStatus = await Permission.bluetoothConnect.request();
    }

    if (micStatus.isGranted &&
        storageStatus.isGranted &&
        bluetoothStatus.isGranted) {
      try {
        log("🎤 Permissions granted, starting recording...");
        final result = await _channel.invokeMethod("startRecording");
        log("🎙️ Result from native: $result");
        setState(() {
          _isRecording = true;
          _statusMessage = 'Recording in progress';
        });
      } catch (e) {
        log("❌ Failed to start recording: $e");
        setState(() {
          _statusMessage = 'Failed to start recording';
        });
      }
    } else {
      log("❌ Permissions denied");
      setState(() {
        _statusMessage = 'Permissions required';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final result = await _channel.invokeMethod("stopRecording");
      log("🎙️ Recording stopped. File saved at: $result");
      setState(() {
        _isRecording = false;
        _statusMessage = 'Recording saved';
      });
    } catch (e) {
      log("❌ Failed to stop recording: $e");
      setState(() {
        _isRecording = false;
        _statusMessage = 'Failed to stop recording';
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _firestore
        .collection('calls')
        .doc(widget.userId)
        .update({'status': 'disconnected'})
        .then((_) => log("📡 Status updated to disconnected"))
        .catchError((error) => log("⚠️ Failed to update status: $error"));

    _remoteRenderer.dispose();
    _peerConnection?.close();
    _remoteStream?.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    if (_isConnected) return _successColor;
    if (_statusMessage.contains('Failed') ||
        _statusMessage.contains('No audio')) {
      return _errorColor;
    }
    if (_statusMessage.contains('Connecting') ||
        _statusMessage.contains('Initializing')) {
      return _warningColor;
    }
    return _textSecondary;
  }

  IconData _getStatusIcon() {
    if (_isConnected) return Icons.radio_button_checked_rounded;
    if (_statusMessage.contains('Failed') ||
        _statusMessage.contains('No audio')) {
      return Icons.error_outline_rounded;
    }
    if (_statusMessage.contains('Connecting') ||
        _statusMessage.contains('Initializing')) {
      return Icons.sync_rounded;
    }
    return Icons.radio_button_unchecked_rounded;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.headset_mic_rounded,
              color: _primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Audio Monitor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connection Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusMessage.isEmpty ? 'Initializing...' : _statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioVisualizer() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isConnected
            ? _primaryColor.withOpacity(0.08)
            : _textSecondary.withOpacity(0.05),
        border: Border.all(
          color: _isConnected
              ? _primaryColor.withOpacity(0.2)
              : _textSecondary.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: _isConnected && _remoteStream != null
          ? AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primaryColor.withOpacity(0.1),
                    ),
                    child: Lottie.asset(
                      'assets/lottie/microphone.json',
                      width: 70,
                      height: 70,
                    ),
                  ),
                );
              },
            )
          : Icon(
              Icons.mic_off_rounded,
              size: 40,
              color: _textSecondary.withOpacity(0.6),
            ),
    );
  }

  Widget _buildRecordingButton() {
    final isEnabled = _isConnected;
    final buttonColor = _isRecording ? _errorColor : _primaryColor;

    return Container(
      width: double.infinity,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: isEnabled ? _toggleRecording : null,
        icon: Icon(
          _isRecording ? Icons.stop_rounded : Icons.fiber_manual_record_rounded,
          size: 20,
        ),
        label: Text(
          _isRecording ? 'Stop Recording' : 'Start Recording',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? buttonColor
              : _textSecondary.withOpacity(0.3),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBackgroundColor: _textSecondary.withOpacity(0.1),
          disabledForegroundColor: _textSecondary.withOpacity(0.6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        foregroundColor: _textPrimary,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        toolbarHeight: 0, // Hide default app bar
      ),
      body: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: Column(
              children: [
                _buildStatusCard(),

                const Spacer(),

                _buildAudioVisualizer(),

                const SizedBox(height: 40),

                _buildRecordingButton(),

                const Spacer(),

                // Audio level indicator (optional enhancement)
                if (_isConnected && _remoteStream != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        const Text(
                          'Audio Level',
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: _textSecondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: LinearProgressIndicator(
                            value:
                                0.7, // This would be dynamic in real implementation
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _primaryColor,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          ),

          // Hidden audio player
          SizedBox(width: 0, height: 0, child: RTCVideoView(_remoteRenderer)),
        ],
      ),
    );
  }
}
