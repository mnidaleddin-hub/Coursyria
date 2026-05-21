import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SecureVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String decryptionKey;
  final String userName;
  final String userPhone;

  const SecureVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.decryptionKey,
    required this.userName,
    required this.userPhone,
  });

  @override
  State<SecureVideoPlayer> createState() => _SecureVideoPlayerState();
}

class _SecureVideoPlayerState extends State<SecureVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  
  // Watermark state
  double _watermarkTop = 50.0;
  double _watermarkLeft = 50.0;
  Timer? _watermarkTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _startWatermarkAnimation();
  }

  Future<void> _initializePlayer() async {
    // In a real AES-128 scenario, we'd decrypt. 
    // For this mock testing with BigBuckBunny, we skip decryption but keep UI shields.
    
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    
    try {
      await _videoPlayerController.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        placeholder: Container(color: Colors.black),
        // Security UI config
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
      );
    } catch (e) {
      debugPrint("Video Init Error: $e");
    }
    
    if (mounted) setState(() {});
  }

  void _startWatermarkAnimation() {
    _watermarkTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _watermarkTop = Random().nextDouble() * 200.h;
          _watermarkLeft = Random().nextDouble() * 200.w;
        });
      }
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    _watermarkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(),
          ),
          
          // Moving Watermark (Anti-Cam Recording)
          AnimatedPositioned(
            duration: const Duration(seconds: 2),
            top: _watermarkTop,
            left: _watermarkLeft,
            child: Opacity(
              opacity: 0.3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.userName, style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                  Text(widget.userPhone, style: TextStyle(color: Colors.white, fontSize: 10.sp)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
