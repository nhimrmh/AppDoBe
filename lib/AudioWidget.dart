import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/cupertino.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioWidget extends StatefulWidget {
  String filePath;
  List<AudioPlayer> list_playing;
  AudioWidget(this.filePath, this.list_playing);

  @override
  AudioWidgetScene createState() => AudioWidgetScene(filePath, list_playing);
}

class AudioWidgetScene extends State<AudioWidget> {
  String filePath;
  AudioCache audioCache = AudioCache();
  AudioPlayer audioPlayer = AudioPlayer();
  Duration duration = Duration();
  Duration position = Duration();
  bool isPlaying = false, isDisposed = false, isDisable = false, isInitial = true;
  AudioPlayerState playerState;
  IconData iconAudio = Icons.play_arrow;
  Color buttonColor = Colors.green;
  List<AudioPlayer> list_playing;

  AudioWidgetScene(this.filePath, this.list_playing);

  void initPlayer() {
    audioCache = AudioCache(fixedPlayer: audioPlayer);

    audioPlayer.durationHandler = (d) => setState((){
      duration = d;
    });

    audioPlayer.positionHandler = (p) => setState((){
      position = p;
    });

    audioPlayer.onPlayerError.listen((msg) {
      setState(() {
        stopAudio();
        duration = Duration(seconds: 0);
        position = Duration(seconds: 0);
      });
    });

    audioPlayer.onPlayerStateChanged.listen((msg) {
      if(isDisposed == false){
        setState(() {
          if(msg == AudioPlayerState.STOPPED || msg == AudioPlayerState.COMPLETED || msg == AudioPlayerState.PAUSED) {
            playerState = msg;
            iconAudio = Icons.play_arrow;
            isPlaying = false;
            buttonColor = Colors.green;
            list_playing.remove(audioPlayer);
          }
          else if(msg == AudioPlayerState.PLAYING){
            list_playing.add(audioPlayer);
            for(int i = 0; i < list_playing.length; i++){
              if(list_playing.elementAt(i).playerId != audioPlayer.playerId){
                list_playing.elementAt(i).pause();
              }
            }
          }
        });
      }
    });
  }

  void initAudio() async {
    await audioCache.play(filePath);
  }

  void playAudio(String filePath) {
    audioCache.play(filePath);
  }

  void stopAudio() async{
    await audioPlayer.stop();
    isPlaying = false;
  }

  void pauseAudio() async{
    await audioPlayer.pause();
    isPlaying = false;
  }

  void resumeAudio() async{
    await audioPlayer.resume();
    isPlaying = true;
  }

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
    iconAudio = Icons.play_arrow;
    isPlaying = false;
    buttonColor = Colors.green;
    audioPlayer.stop();
  }

  @override
  void initState() {
    super.initState();
    initPlayer();
  }

  @override
  Widget build(BuildContext context) {
    //pauseAudio();
    // TODO: implement build
    return Container(
      margin: EdgeInsets.only(right: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 0),
            child: IconButton(
              onPressed: (){
                setState(() {
                  if(isInitial){
                    isInitial = false;
                    isPlaying = true;
                    playAudio(filePath);
                    iconAudio = Icons.pause;
                    buttonColor = Colors.red;

                  }
                  else{
                    if(isPlaying) {
                      pauseAudio();
                      iconAudio = Icons.play_arrow;
                      buttonColor = Colors.green;
                    }
                    else {
                      resumeAudio();
                      iconAudio = Icons.pause;
                      buttonColor = Colors.red;
                    }
                  }
                });
              },
              icon: Icon(iconAudio, size: 30),
              color: buttonColor,
            ),
          ),
          Container(
              child: Row(
                children: <Widget>[
                  Text(
                    position.inMinutes.toInt().toString(),
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    ":",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    position.inSeconds.toInt().toString().length == 1 ? "0" + position.inSeconds.toInt().toString() : position.inSeconds.toInt().toString(),
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              )
          ),

        ],
      ),
    );
  }
}