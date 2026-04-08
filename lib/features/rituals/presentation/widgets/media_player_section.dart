import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaPlayerSection extends StatefulWidget {
  const MediaPlayerSection({super.key, required this.mediaUrl});
  final String mediaUrl;

  @override
  State<MediaPlayerSection> createState() => _MediaPlayerSectionState();
}

class _MediaPlayerSectionState extends State<MediaPlayerSection> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.mediaUrl.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl))
        ..initialize().then((_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        IconButton(
          onPressed: () {
            if (_controller!.value.isPlaying) {
              _controller!.pause();
            } else {
              _controller!.play();
            }
            setState(() {});
          },
          icon: Icon(
            _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
      ],
    );
  }
}
