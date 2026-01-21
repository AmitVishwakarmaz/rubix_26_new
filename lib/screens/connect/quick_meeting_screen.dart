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
  EventsListener<RoomEvent>? _listener;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _cameraEnabled = false;
  bool _micEnabled = false;
  String _permissionStatus = '';
  int _participantCount = 1; // Start with 1 (self)
  
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
    // Use the provided room name - this ensures both users join the same room
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
    
    print('🎥 Meeting initialized: Room=$_roomName');
    _requestPermissionsAndJoin();
  }
  
  Future<String> _generateToken(String roomName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final identity = currentUser?.displayName ?? currentUser?.email ?? 'User_${const Uuid().v4().substring(0, 4)}';
    
    print('🔐 Generating token for: $identity in room: $roomName');
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
      
      // Set up event listener BEFORE connecting
      _listener = room.createListener();
      _setupRoomListeners();

      print('🔌 Connecting to room: $_roomName');
      
      await room.connect(
        _serverUrl,
        _token,
        roomOptions: const RoomOptions(
          adaptiveStream: true, 
          dynacast: true,
        ),
      );

      print('✅ Connected to room! Participants: ${room.remoteParticipants.length + 1}');

      // Try to enable camera & mic
      try {
        await room.localParticipant?.setCameraEnabled(true);
        setState(() => _cameraEnabled = true);
        print('📷 Camera enabled');
      } catch (e) {
        debugPrint('Camera enable failed: $e');
      }

      try {
        await room.localParticipant?.setMicrophoneEnabled(true);
        setState(() => _micEnabled = true);
        print('🎤 Microphone enabled');
      } catch (e) {
        debugPrint('Mic enable failed: $e');
      }

      setState(() {
        _room = room;
        _isConnected = true;
        _isConnecting = false;
        _participantCount = room.remoteParticipants.length + 1;
      });
    } catch (e) {
      print('❌ Connection failed: $e');
      setState(() => _isConnecting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection failed: $e")),
        );
      }
    }
  }

  void _setupRoomListeners() {
    _listener?.on<ParticipantConnectedEvent>((event) {
      print('👤 Participant joined: ${event.participant.identity}');
      setState(() {
        _participantCount = (_room?.remoteParticipants.length ?? 0) + 1;
      });
    });

    _listener?.on<ParticipantDisconnectedEvent>((event) {
      print('👤 Participant left: ${event.participant.identity}');
      setState(() {
        _participantCount = (_room?.remoteParticipants.length ?? 0) + 1;
      });
    });

    _listener?.on<TrackSubscribedEvent>((event) {
      print('📹 Track subscribed: ${event.track.kind} from ${event.participant.identity}');
      setState(() {}); // Trigger rebuild to show the new track
    });

    _listener?.on<TrackUnsubscribedEvent>((event) {
      print('📹 Track unsubscribed: ${event.track.kind}');
      setState(() {}); // Trigger rebuild
    });

    _listener?.on<TrackMutedEvent>((event) {
      print('🔇 Track muted');
      setState(() {});
    });

    _listener?.on<TrackUnmutedEvent>((event) {
      print('🔊 Track unmuted');
      setState(() {});
    });

    _listener?.on<LocalTrackPublishedEvent>((event) {
      print('📤 Local track published: ${event.publication.kind}');
      setState(() {});
    });
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
    _listener?.dispose();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _listener?.dispose();
    _room?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(_isConnected ? _meetingTitle : 'Connecting...'),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isConnected) ...[
            // Participant count badge
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 18, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 4),
                  Text(
                    '$_participantCount',
                    style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: _leaveMeeting,
          ),
        ],
      ),
      body: _isConnecting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  const SizedBox(height: 16),
                  Text(
                    _permissionStatus.isNotEmpty ? _permissionStatus : 'Connecting to meeting...',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Room: $_roomName',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
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
                onPressed: _requestPermissionsAndJoin,
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
    final remoteParticipants = _room?.remoteParticipants.values.toList() ?? [];
    
    return Stack(
      children: [
        // Remote participants
        remoteParticipants.isEmpty
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
                    const SizedBox(height: 8),
                    Text(
                      'Room: $_roomName',
                      style: const TextStyle(fontSize: 12, color: Colors.white38),
                    ),
                  ],
                ),
              )
            : _buildRemoteParticipantsGrid(remoteParticipants),

        // Local preview (small)
        Positioned(
          bottom: 100,
          right: 16,
          child: _buildLocalPreview(),
        ),

        // Controls
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: _buildControls(),
        ),
      ],
    );
  }

  Widget _buildRemoteParticipantsGrid(List<RemoteParticipant> participants) {
    if (participants.length == 1) {
      // Single remote participant - full screen
      return _buildParticipantView(participants.first);
    }
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: participants.length <= 2 ? 1 : 2,
        childAspectRatio: participants.length <= 2 ? 0.75 : 0.8,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(4),
          child: _buildParticipantView(participants[index]),
        );
      },
    );
  }

  Widget _buildParticipantView(RemoteParticipant participant) {
    // Find the video track
    VideoTrack? videoTrack;
    
    for (final pub in participant.videoTrackPublications) {
      if (pub.subscribed && pub.track != null && !pub.muted) {
        videoTrack = pub.track as VideoTrack?;
        break;
      }
    }
    
    print('🎬 Rendering participant ${participant.identity}: hasVideo=${videoTrack != null}');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (videoTrack != null)
              VideoTrackRenderer(
                videoTrack,
                fit: VideoViewFit.cover,
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF6C63FF).withOpacity(0.4),
                      child: Text(
                        participant.identity.isNotEmpty 
                            ? participant.identity.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      participant.identity,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            // Name overlay
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  participant.identity,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalPreview() {
    VideoTrack? localVideoTrack;
    
    final localParticipant = _room?.localParticipant;
    if (localParticipant != null) {
      for (final pub in localParticipant.videoTrackPublications) {
        if (pub.track != null && !pub.muted) {
          localVideoTrack = pub.track as VideoTrack?;
          break;
        }
      }
    }

    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C63FF), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            if (localVideoTrack != null && _cameraEnabled)
              VideoTrackRenderer(
                localVideoTrack,
                fit: VideoViewFit.cover,
                mirrorMode: VideoViewMirrorMode.mirror,
              )
            else
              const Center(
                child: Icon(Icons.person, size: 60, color: Colors.white54),
              ),
            // You label
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
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
