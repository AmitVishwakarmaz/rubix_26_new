import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

class QuickMeetingScreen extends StatefulWidget {
  final String? roomName;
  final String? token;
  final String? title;
  final DateTime? scheduledTime;
  // Legacy support for old parameter names
  final String? meetingTitle;

  const QuickMeetingScreen({
    super.key,
    this.roomName,
    this.token,
    this.title,
    this.meetingTitle,
    this.scheduledTime,
  });

  @override
  State<QuickMeetingScreen> createState() => _QuickMeetingScreenState();
}

class _QuickMeetingScreenState extends State<QuickMeetingScreen> {
  final String _serverUrl = 'wss://fitsync-yykk3win.livekit.cloud';

  Room? _room;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _cameraEnabled = false;
  bool _micEnabled = false;
  String _permissionStatus = '';
  
  // Computed properties with defaults
  late String _roomName;
  late String _token;
  late String _meetingTitle;
  late DateTime _scheduledTime;

  @override
  void initState() {
    super.initState();
    _initializeMeeting();
  }
  
  Future<void> _initializeMeeting() async {
    // Generate room name if not provided
    _roomName = widget.roomName ?? 'meeting_${const Uuid().v4().substring(0, 8)}';
    
    // Get meeting title
    _meetingTitle = widget.title ?? widget.meetingTitle ?? 'Video Meeting';
    
    // Get scheduled time or use now
    _scheduledTime = widget.scheduledTime ?? DateTime.now();
    
    // Generate token if not provided
    if (widget.token != null && widget.token!.isNotEmpty) {
      _token = widget.token!;
    } else {
      _token = await _generateToken(_roomName);
    }
    
    _requestPermissionsAndJoin();
  }
  
  Future<String> _generateToken(String roomName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final identity = currentUser?.displayName ?? currentUser?.email ?? 'User_${const Uuid().v4().substring(0, 4)}';
    
    return MeetingService.generateToken(roomName: roomName, identity: identity);
  }

  Future<void> _requestPermissionsAndJoin() async {
    setState(() {
      _isConnecting = true;
      _permissionStatus = 'Requesting permissions...';
    });

    // Request camera permission
    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
    }

    // Request microphone permission
    var micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
    }

    if (cameraStatus.isGranted && micStatus.isGranted) {
      setState(() => _permissionStatus = 'Connecting to meeting...');
      await _joinMeeting();
    } else if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      setState(() {
        _isConnecting = false;
        _permissionStatus = 'Permissions permanently denied. Please enable in Settings.';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Camera/Microphone permissions are required'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    } else {
      setState(() {
        _isConnecting = false;
        _permissionStatus = 'Permissions denied';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera and Microphone permissions are required for video calls'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _joinMeeting() async {
    try {
      final room = Room();

      await room.connect(
        _serverUrl,
        _token,
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );

      // Try to enable camera & mic
      try {
        await room.localParticipant?.setCameraEnabled(true);
        setState(() => _cameraEnabled = true);
      } catch (e) {
        debugPrint('Camera enable failed: $e');
      }

      try {
        await room.localParticipant?.setMicrophoneEnabled(true);
        setState(() => _micEnabled = true);
      } catch (e) {
        debugPrint('Mic enable failed: $e');
      }

      setState(() {
        _room = room;
        _isConnected = true;
        _isConnecting = false;
      });
    } catch (e) {
      setState(() => _isConnecting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection failed: $e")),
        );
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (_room == null) return;
    final enabled = !_cameraEnabled;
    await _room!.localParticipant?.setCameraEnabled(enabled);
    setState(() => _cameraEnabled = enabled);
  }

  Future<void> _toggleMic() async {
    if (_room == null) return;
    final enabled = !_micEnabled;
    await _room?.localParticipant?.setMicrophoneEnabled(enabled);
    setState(() => _micEnabled = enabled);
  }

  Future<void> _leaveMeeting() async {
    await _room?.disconnect();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _room?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(_meetingTitle),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: _leaveMeeting,
          ),
        ],
      ),
      body: _isConnecting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  SizedBox(height: 16),
                  Text(
                    'Connecting to meeting...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : _isConnected
              ? _buildVideoUI()
              : _buildPreJoinUI(),
    );
  }

  Widget _buildPreJoinUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.video_call_rounded,
                size: 80,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _meetingTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Room: $_roomName',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _joinMeeting,
                icon: const Icon(Icons.login),
                label: const Text(
                  'Join Meeting',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoUI() {
    return Stack(
      children: [
        // Remote participants
        _room!.remoteParticipants.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people_outline,
                        size: 60,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Waiting for others to join...',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                ),
                itemCount: _room!.remoteParticipants.length,
                itemBuilder: (context, index) {
                  final participant =
                      _room!.remoteParticipants.values.elementAt(index);
                  final videoTrack =
                      participant.videoTrackPublications.isNotEmpty
                          ? participant.videoTrackPublications
                              .firstWhere(
                                (pub) =>
                                    pub.kind == TrackType.VIDEO &&
                                    pub.track != null,
                                orElse: () =>
                                    participant.videoTrackPublications.first,
                              )
                              .track
                          : null;

                  return videoTrack != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: VideoTrackRenderer(
                            videoTrack,
                            fit: VideoViewFit.cover,
                          ),
                        )
                      : Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                const Color(0xFF6C63FF).withOpacity(0.4),
                            child: Text(
                              participant.identity
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                },
              ),

        // Local preview (small)
        Positioned(
          bottom: 100,
          right: 16,
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6C63FF), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _room!.localParticipant?.videoTrackPublications.any(
                        (pub) =>
                            pub.kind == TrackType.VIDEO && pub.track != null,
                      ) ??
                      false
                  ? VideoTrackRenderer(
                      _room!.localParticipant!.videoTrackPublications
                          .firstWhere(
                            (pub) =>
                                pub.kind == TrackType.VIDEO && pub.track != null,
                          )
                          .track!,
                      fit: VideoViewFit.cover,
                    )
                  : const Center(
                      child: Icon(Icons.person, size: 60, color: Colors.white54),
                    ),
            ),
          ),
        ),

        // Controls
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _micEnabled ? Icons.mic : Icons.mic_off,
                  isActive: _micEnabled,
                  onPressed: _toggleMic,
                  label: _micEnabled ? 'Mute' : 'Unmute',
                ),
                _buildControlButton(
                  icon: _cameraEnabled ? Icons.videocam : Icons.videocam_off,
                  isActive: _cameraEnabled,
                  onPressed: _toggleCamera,
                  label: _cameraEnabled ? 'Camera Off' : 'Camera On',
                ),
                _buildControlButton(
                  icon: Icons.call_end,
                  isActive: false,
                  onPressed: _leaveMeeting,
                  label: 'Leave',
                  isLeave: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required String label,
    bool isLeave = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isLeave
                ? Colors.red
                : (isActive
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withOpacity(0.1)),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive || isLeave ? Colors.white : Colors.red,
            ),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }
}

/// Service for creating meeting tokens
class MeetingService {
  static const String _apiKey = 'API3NwTjX3rnPz2';
  static const String _apiSecret = 'L8eEOQdG4gKAfi2zi2Qm9eJCkZChw0dh7iBDecw6xcKA';

  /// Generate a token for a meeting
  static String generateToken({
    required String roomName,
    required String identity,
  }) {
    final jwt = JWT({
      'video': {
        'roomJoin': true,
        'room': roomName,
        'roomAdmin': true,
        'canPublish': true,
        'canSubscribe': true,
      },
      'sub': identity,
      'name': identity,
      'exp': DateTime.now()
              .add(const Duration(hours: 24))
              .millisecondsSinceEpoch ~/
          1000,
    }, issuer: _apiKey);

    return jwt.sign(
      SecretKey(_apiSecret),
      algorithm: JWTAlgorithm.HS256,
    );
  }

  /// Create a unique room name
  static String generateRoomName() {
    return 'meeting_${const Uuid().v4().substring(0, 12)}';
  }
}
