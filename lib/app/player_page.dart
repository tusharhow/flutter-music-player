import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'dart:math' as math;
import '../utils/song_util.dart';
import '../constants.dart';


class PlayerPage extends StatefulWidget {
  const PlayerPage({required this.player, Key? key}) : super(key: key);
  final AssetsAudioPlayer player;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isPlaying = true;
  late final AnimationController _animationController =
      AnimationController(vsync: this, duration: const Duration(seconds: 30));

  @override
  void initState() {
    widget.player.isPlaying.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = event;
        });
      }
    });
    widget.player.onReadyToPlay.listen((newDuration) {
      if (mounted) {
        setState(() {
          duration = newDuration?.duration ?? Duration.zero;
        });
      }
    });
    widget.player.currentPosition.listen((newPosition) {
      if (mounted) {
        setState(() {
          position = newPosition;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 30,
                color: Colors.white,
              )),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          FutureBuilder<PaletteGenerator>(
            future: getPosterColors(widget.player),
            builder: (context, snapshot) {
              return Container(
                color: snapshot.data?.mutedColor?.color,
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(.7)]),
              ),
            ),
          ),
          Positioned(
            height: MediaQuery.of(context).size.height / 1.5,
            child: Column(
              children: [
                Text(
                  widget.player.getCurrentAudioTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  widget.player.getCurrentAudioArtist,
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 25,
                ),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Text(
                        durationFormat(position),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const VerticalDivider(
                        color: Colors.white54,
                        thickness: 2,
                        width: 25,
                        indent: 2,
                        endIndent: 2,
                      ),
                      Text(
                        durationFormat(duration - position),
                        style: const TextStyle(color: kPrimaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Center(
              child: SleekCircularSlider(
            min: 0.0,
            max: duration.inSeconds.toDouble(),
            initialValue: position.inSeconds.toDouble(),
            onChange: (value) async {
              await widget.player.seek(Duration(seconds: value.toInt()));
            },
            innerWidget: (percentage) {
              return Padding(
                padding: const EdgeInsets.all(25.0),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    if (!isPlaying) {
                      _animationController.stop();
                    } else {
                      if (mounted) {
                        _animationController.repeat();
                      }
                    }
                    return Transform.rotate(
                        angle: _animationController.value * 2 * math.pi,
                        child: child);
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.grey,
                    backgroundImage: AssetImage(
                        widget.player.getCurrentAudioImage?.path ?? ''),
                  ),
                ),
              );
            },
            appearance: CircularSliderAppearance(
                size: 330,
                angleRange: 300,
                startAngle: 300,
                customColors: CustomSliderColors(
                  progressBarColor: kPrimaryColor,
                  dotColor: kPrimaryColor,
                  trackColor: Colors.grey.withOpacity(.4),
                ),
                customWidths: CustomSliderWidths(
                    trackWidth: 6, handlerSize: 10, progressBarWidth: 6)),
          )),
          Positioned(
            top: MediaQuery.of(context).size.height / 1.3,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                      onPressed: () async {
                        await widget.player.previous();
                        _animationController.reset();
                      },
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        size: 50,
                        color: Colors.white,
                      )),
                  IconButton(
                    onPressed: () async {
                      await widget.player.playOrPause();
                    },
                    padding: EdgeInsets.zero,
                    icon: isPlaying
                        ? const Icon(
                            Icons.pause_circle,
                            size: 70,
                            color: Colors.white,
                          )
                        : const Icon(
                            Icons.play_circle,
                            size: 70,
                            color: Colors.white,
                          ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await widget.player.next();
                      // image transform reset
                      _animationController.reset();
                    },
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
