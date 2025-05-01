import 'dart:async';
import 'dart:ui';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../services/video_call_settings.dart';

class CallPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  final String? channelName;

  /// non-modifiable client role of the page
  final ClientRole? role;

  /// Creates a call page with given channel name.
  const CallPage({Key? key, this.channelName, this.role}) : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage>
    with SingleTickerProviderStateMixin {
  final _users = <int>[]; // List of remote user IDs
  final _infoStrings = <String>[];
  bool muted = false;
  bool videoEnabled = true;
  bool isFullScreen = false;
  bool showControls = true;
  bool showInfo = false;
  late RtcEngine _engine;
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _controlsTimer;

  // Call duration tracking
  Stopwatch _callDuration = Stopwatch();
  String _durationText = "00:00";
  Timer? _durationTimer;

  @override
  void dispose() {
    _users.clear();
    _dispose();
    _animationController.dispose();
    _controlsTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.destroy();
  }

  @override
  void initState() {
    super.initState();
    initialize();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Start call duration timer
    _callDuration.start();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final minutes = (_callDuration.elapsedMilliseconds / 60000).floor();
      final seconds =
          ((_callDuration.elapsedMilliseconds % 60000) / 1000).floor();
      setState(() {
        _durationText =
            "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      });
    });

    // Auto-hide controls after 5 seconds
    _resetControlsTimer();
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    setState(() {
      showControls = true;
    });
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        showControls = false;
      });
    });
  }

  Future<void> initialize() async {
    if (appId.isEmpty) {
      setState(() {
        _infoStrings
            .add('APP_ID missing, please provide your APP_ID in settings.dart');
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }

    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = const VideoDimensions(width: 1920, height: 1080);
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(token, widget.channelName!, null, 0);
  }

  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(appId);
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(widget.role!);
  }

  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(
      error: (code) {
        setState(() {
          _infoStrings.add('onError: $code');
        });
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          _infoStrings.add('onJoinChannel: $channel, uid: $uid');
        });
      },
      leaveChannel: (stats) {
        setState(() {
          _infoStrings.add('onLeaveChannel');
          _users.clear();
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          _infoStrings.add('userJoined: $uid');
          _users.add(uid);
        });
      },
      userOffline: (uid, elapsed) {
        setState(() {
          _infoStrings.add('userOffline: $uid');
          _users.remove(uid);
        });
      },
      firstRemoteVideoFrame: (uid, width, height, elapsed) {
        setState(() {
          _infoStrings.add('firstRemoteVideo: $uid ${width}x$height');
        });
      },
    ));
  }

  // Improved video view for one-to-one call
  Widget _viewRows() {
    final List<Widget> views = [];
    // Local video (doctor)
    if (widget.role == ClientRole.Broadcaster) {
      views.add(const RtcLocalView.SurfaceView());
    }
    // Remote video (patient)
    if (_users.isNotEmpty) {
      views.add(RtcRemoteView.SurfaceView(
        uid: _users[0], // Only one remote user in one-to-one
        channelId: widget.channelName!,
      ));
    }

    return GestureDetector(
      onTap: () {
        _resetControlsTimer();
      },
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A2151), Color(0xFF0D1128)],
              ),
            ),
          ),

          // Remote video (full screen)
          if (views.length > 1)
            Container(
              child: views[1], // Patient's video
            ),

          // Connection status indicator
          if (_users.isEmpty && widget.role == ClientRole.Broadcaster)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Waiting for other participant...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

          // Local video (small preview)
          if (views.length > 0)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              right: 16,
              top: isFullScreen ? 16 : 80,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isFullScreen = !isFullScreen;
                  });
                  _resetControlsTimer();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isFullScreen ? 150 : 100,
                  height: isFullScreen ? 200 : 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: views[0], // Doctor's video
                ),
              ),
            ),

          // Call duration display
          AnimatedOpacity(
            opacity: showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _durationText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Improved toolbar with modern design
  Widget _toolbar() {
    if (widget.role == ClientRole.Audience) return Container();

    return AnimatedOpacity(
      opacity: showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 48),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Mute button
                  _buildControlButton(
                    onPressed: _onToggleMute,
                    icon: muted ? Icons.mic_off : Icons.mic,
                    color: muted ? Colors.red : Colors.white,
                    backgroundColor: muted
                        ? Colors.red.withOpacity(0.2)
                        : Colors.white.withOpacity(0.2),
                    tooltip: muted ? 'Unmute' : 'Mute',
                  ),

                  const SizedBox(width: 16),

                  // Video toggle button
                  _buildControlButton(
                    onPressed: _onToggleVideo,
                    icon: videoEnabled ? Icons.videocam : Icons.videocam_off,
                    color: videoEnabled ? Colors.white : Colors.red,
                    backgroundColor: videoEnabled
                        ? Colors.white.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    tooltip:
                        videoEnabled ? 'Turn off camera' : 'Turn on camera',
                  ),

                  const SizedBox(width: 16),

                  // End call button
                  _buildControlButton(
                    onPressed: () => _onCallEnd(context),
                    icon: Icons.call_end,
                    color: Colors.white,
                    backgroundColor: Colors.red,
                    size: 30,
                    padding: 16,
                    tooltip: 'End call',
                  ),

                  const SizedBox(width: 16),

                  // Switch camera button
                  _buildControlButton(
                    onPressed: _onSwitchCamera,
                    icon: Icons.switch_camera,
                    color: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    tooltip: 'Switch camera',
                  ),

                  const SizedBox(width: 16),

                  // Info button
                  _buildControlButton(
                    onPressed: () {
                      setState(() {
                        showInfo = !showInfo;
                      });
                      _resetControlsTimer();
                    },
                    icon: showInfo ? Icons.info_outline : Icons.info,
                    color: showInfo ? Colors.blue : Colors.white,
                    backgroundColor: showInfo
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.white.withOpacity(0.2),
                    tooltip: showInfo ? 'Hide info' : 'Show info',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    double size = 24,
    double padding = 12,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onPressed();
            _resetControlsTimer();
          },
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: size,
            ),
          ),
        ),
      ),
    );
  }

  // Improved info panel with animation
  Widget _panel() {
    return AnimatedOpacity(
      opacity: showInfo ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Visibility(
        visible: showInfo,
        child: Container(
          padding: const EdgeInsets.only(top: 80),
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            constraints: const BoxConstraints(
              maxHeight: 200,
              maxWidth: 300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Call Information",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Raleway',
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.2)),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _infoStrings.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (_infoStrings.isEmpty) {
                        return const Text("No information available",
                            style: TextStyle(
                                color: Colors.white70, fontFamily: 'Raleway'));
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          _infoStrings[index],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onCallEnd(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "End Call",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: AppColors.deepPurple, // 💜 HealthHub Theme
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Animation
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent, // 🔴 Accent color for warning
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    "End Call",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Raleway',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  const Text(
                    "Are you sure you want to disconnect the call?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel Button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Raleway',
                            color: Colors.white70,
                          ),
                        ),
                      ),

                      // End Call Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Exit call page
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                          backgroundColor: Colors.redAccent, // 🔴 Accent Red
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "End Call",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Raleway',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onToggleVideo() {
    setState(() {
      videoEnabled = !videoEnabled;
    });
    _engine.enableLocalVideo(videoEnabled);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();

    // Add a little animation for feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Camera switched'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.only(
          bottom: 100,
          left: 50,
          right: 50,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          // widget.channelName ?? 'Video Call',
          'Video Call',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Raleway',
              color: Colors.white),
        ),
        centerTitle: true,
        leading: AnimatedOpacity(
          opacity: showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
            ),
            onPressed: () => _onCallEnd(context),
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: <Widget>[
            _viewRows(),
            _panel(),
            _toolbar(),
          ],
        ),
      ),
    );
  }
}
