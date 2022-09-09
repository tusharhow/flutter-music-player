import 'dart:math' as math;
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../utils/song_data.dart';
import '../utils/song_util.dart';
import 'player_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final player = AssetsAudioPlayer();
  bool isPlaying = true;

  // define an animation controller for rotate the song cover image
  late final AnimationController _animationController =
      AnimationController(vsync: this, duration: const Duration(seconds: 10));

  @override
  void initState() {
    startPlayer();
    player.isPlaying.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = event;
        });
      }
    });
    super.initState();
  }

  // define a playlist for player
  void startPlayer() async {
    await player.open(Playlist(audios: songs),
        autoStart: false, showNotification: true, loopMode: LoopMode.playlist);
  }

  @override
  void dispose() {
    player.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.withOpacity(.2),
      appBar: AppBar(
        title: const Text(
          'Mex Player',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SafeArea(
              child: ListView.separated(
            separatorBuilder: (context, index) {
              return const Divider(
                color: Colors.white24,
                height: 0,
                thickness: 1,
                indent: 85,
                endIndent: 20,
              );
            },
            itemCount: songs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ListTile(
                  title: Text(
                    songs[index].metas.title!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    songs[index].metas.artist!,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(songs[index].metas.image!.path)),
                  onTap: () async {
                    await player.playlistPlayAtIndex(index);
                    setState(() {
                      player.getCurrentAudioImage;
                      player.getCurrentAudioTitle;
                    });
                  },
                ),
              );
            },
          )),
          player.getCurrentAudioImage == null
              ? const SizedBox.shrink()
              : FutureBuilder<PaletteGenerator>(
                  future: getPosterColors(player),
                  builder: (context, snapshot) {
                    return Dismissible(
                      key: UniqueKey(),
                      onDismissed: (direction) {
                        player.stop();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 50),
                        height: 75,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: const Alignment(0, 5),
                                colors: [
                                  snapshot.data?.lightMutedColor?.color ??
                                      Colors.grey,
                                  snapshot.data?.mutedColor?.color ??
                                      Colors.grey,
                                ]),
                            borderRadius: BorderRadius.circular(20)),
                        child: ListTile(
                          leading: AnimatedBuilder(
                            // rotate the song cover image
                            animation: _animationController,
                            builder: (_, child) {
                              // if song is not playing
                              if (!isPlaying) {
                                _animationController.stop();
                              } else {
                                _animationController.forward();
                                _animationController.repeat();
                              }
                              return Transform.rotate(
                                  angle:
                                      _animationController.value * 2 * math.pi,
                                  child: child);
                            },
                            child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey,
                                backgroundImage: AssetImage(
                                    player.getCurrentAudioImage?.path ?? '')),
                          ),
                          // onTap: () => Navigator.push(
                          //     context,
                          //     CupertinoPageRoute(
                          //         fullscreenDialog: true,
                          //         builder: (context) => PlayerPage(
                          //               player: player,
                          //             ))),
                          onTap: () {
                            showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                elevation: 0,
                                builder: (context) {
                                  return FractionallySizedBox(
                                    heightFactor: 0.96,
                                    child: PlayerPage(
                                      player: player,
                                    ),
                                  );
                                });
                          },
                          title: Text(player.getCurrentAudioTitle),
                          subtitle: Text(player.getCurrentAudioArtist),
                          trailing: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              await player.playOrPause();
                            },
                            icon: isPlaying
                                ? const Icon(Icons.pause)
                                : const Icon(Icons.play_arrow),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
