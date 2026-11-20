import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoBaiHoc extends StatefulWidget {
  const VideoBaiHoc({
    super.key,
    required this.youtubeId,
    this.kenhYouTube,
    this.onThoiGianHoc,
  });

  final String youtubeId;
  final String? kenhYouTube;

  /// Gọi định kỳ khi video đang phát thực tế để tích lũy thời gian học
  final void Function(int giay)? onThoiGianHoc;

  @override
  State<VideoBaiHoc> createState() => _VideoBaiHocState();
}

class _VideoBaiHocState extends State<VideoBaiHoc> {
  YoutubePlayerController? _trinhPhat;
  Timer? _boDemGio;
  StreamSubscription? _dangKyTrangThai;

  @override
  void initState() {
    super.initState();
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      _trinhPhat = YoutubePlayerController.fromVideoId(
        videoId: widget.youtubeId,
        autoPlay: false,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );

      _dangKyTrangThai = _trinhPhat?.stream.listen((value) {
        if (value.playerState == PlayerState.playing) {
          _batDauDemGio();
        } else {
          _dungDemGio();
        }
      });
    }
  }

  void _batDauDemGio() {
    _boDemGio?.cancel();
    _boDemGio = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        widget.onThoiGianHoc?.call(10);
      }
    });
  }

  void _dungDemGio() {
    _boDemGio?.cancel();
    _boDemGio = null;
  }

  @override
  void dispose() {
    _dungDemGio();
    _dangKyTrangThai?.cancel();
    _trinhPhat?.close();
    super.dispose();
  }

  Future<void> _moYouTube() async {
    final uri = Uri.https('www.youtube.com', '/watch', {'v': widget.youtubeId});
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Hiện phản hồi khi nền tảng không mở được liên kết.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được video YouTube.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trinhPhat = _trinhPhat;
    final kenh = widget.kenhYouTube;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trinhPhat != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: YoutubePlayer(controller: trinhPhat, aspectRatio: 16 / 9),
          ),
        TextButton.icon(
          onPressed: _moYouTube,
          icon: const Icon(Icons.open_in_new),
          label: Text(
            kenh == null ? 'Mở video trên YouTube' : 'Xem trên YouTube · $kenh',
          ),
        ),
      ],
    );
  }
}
