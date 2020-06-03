import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

Future delayReload() async {
  await Future.delayed(const Duration(milliseconds: 1000), (){
    return;
  });
}

class VideoState extends StatefulWidget {
  String videoName;
  bool isExpanded;
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return VideoScene(videoName, isExpanded);
  }

  VideoState(this.videoName, this.isExpanded);
}

class videoScreenScene extends StatefulWidget {
  VideoPlayerController _videoPlayerController;
  Duration _duration;
  Duration _position;
  Icon playIcon;
  videoScreenScene(this._videoPlayerController, this._position, this._duration, this.playIcon);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return videoScreen(_videoPlayerController, _position, _duration, playIcon);
  }
}

class videoScreen extends State<videoScreenScene> with SingleTickerProviderStateMixin{
  double aspectRatio = 16/9;
  bool isShow = true, isFullScreen = false;
  AnimationController controller_true;
  Animation fadeOutAnimation;
  VideoPlayerController _videoPlayerController;
  Icon playIcon;
  Duration _duration;
  Duration _position;
  bool _isPlaying = false, isDisposed = false;
  bool _isEnd = false;
  videoScreen(this._videoPlayerController, this._position, this._duration, this.playIcon);

  @override
  void initState() {
    isDisposed = false;
    controller_true = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500)
    );

    fadeOutAnimation = Tween(
        begin: 1.0,
        end: 0.0
    ).animate(controller_true);

    _videoPlayerController..addListener(() {
      final bool isPlaying = _videoPlayerController.value.isPlaying;
      if (isPlaying != _isPlaying) {
        if(isDisposed == false){
          setState(() {
            _isPlaying = isPlaying;
          });
        }
      }
      Timer.run(() {
        if(isDisposed == false){
          this.setState((){
            _position = _videoPlayerController.value.position;
          });
        }
      });
      if(isDisposed == false){
        setState(() {
          _duration = _videoPlayerController.value.duration;
        });
      }
      if(isDisposed == false){
        _duration?.compareTo(_position) == 0 || _duration?.compareTo(_position) == -1 ? this.setState((){
          _isEnd = true;
          playIcon = Icon(Icons.play_arrow, color: Colors.white, size: 30);
        }) : this.setState((){
          _isEnd = false;
        });
      }
    });
    _videoPlayerController.setLooping(true);
  }

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }

  void seekToSecond(int second){
    Duration newDuration = Duration(seconds: second);
    _videoPlayerController.seekTo(newDuration);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Container(
          width: double.infinity,
          height: double.infinity,
          child: AspectRatio(
              aspectRatio: aspectRatio,
              // Use the VideoPlayer widget to display the video.
              child: GestureDetector(
                  onTap: (){
                    if(isShow == false){
                      controller_true.reverse();
                      isShow = true;
                    }
                    else{
                      controller_true.forward();
                      isShow = false;
                    }
                    setState(() {
                      if(_videoPlayerController.value.isPlaying){
                        playIcon = Icon(Icons.play_arrow, color: Colors.white, size: 30);
                        _videoPlayerController.pause();
                      }
                      else {
                        playIcon = Icon(Icons.pause, color: Colors.white, size: 30);
                        _videoPlayerController.play();
                        isShow = false;
                        controller_true.forward();
                      }
                    });
                  },
                  onDoubleTap: (){
                    Navigator.pop(context);
                  },
                  child: RotatedBox(
                    quarterTurns: _videoPlayerController.value.aspectRatio >= 1.5 ? 1 : 0,
                    child: Stack(
                      children: <Widget>[
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.black,
                        ),
                        Center(
                          child: AspectRatio(
                            aspectRatio: _videoPlayerController.value.aspectRatio,
                            child: VideoPlayer(_videoPlayerController),
                          ),
                        ),
                        Align(
                            alignment: Alignment.bottomLeft,
                            child: FadeTransition(
                              opacity: fadeOutAnimation,
                              child: Container(
                                  color: Colors.black54,
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        margin: _videoPlayerController.value.aspectRatio >= 1.5 ? EdgeInsets.only(bottom: 10) : EdgeInsets.only(left: 10),
                                        child: IconButton(
                                          icon: playIcon,
                                          onPressed: (){
                                            setState(() {
                                              if(_videoPlayerController.value.isPlaying){
                                                playIcon = Icon(Icons.play_arrow, color: Colors.white, size: 30);
                                                _videoPlayerController.pause();
                                              }
                                              else {
                                                playIcon = Icon(Icons.pause, color: Colors.white, size: 30);
                                                _videoPlayerController.play();
                                                isShow = false;
                                                controller_true.forward();
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      Expanded(
                                          child: Container(
                                            margin: _videoPlayerController.value.aspectRatio >= 1.5 ? EdgeInsets.only(bottom: 10) : EdgeInsets.only(left: 0),
                                            height: 30,
                                            child: Slider(
                                              activeColor: Colors.red,
                                              inactiveColor: Colors.white,
                                              value: _position != null ? _position.inSeconds.toDouble() : 0,
                                              min: 0.0,
                                              max: _duration != null ? _duration.inSeconds.toDouble() : 0,
                                              onChanged: (double value){
                                                setState(() {
                                                  seekToSecond(value.toInt());
                                                  value = value;
                                                  _videoPlayerController.play();
                                                  playIcon = Icon(Icons.pause, color: Colors.white, size: 30);
                                                });
                                              },
                                            ),
                                          )
                                      ),
                                      Container(
                                        margin: _videoPlayerController.value.aspectRatio >= 1.5 ? EdgeInsets.only(bottom: 10, right: 10) : EdgeInsets.only(right: 10),
                                        child: Row(
                                          children: <Widget>[
                                            Text(_position != null ? _position.inMinutes.toString() : "0", style: TextStyle(color: Colors.white, fontSize: 18),),
                                            Text(":", style: TextStyle(color: Colors.white, fontSize: 18),),
                                            Text(_position != null ? (_position.inSeconds >= 10 ? _position.inSeconds.toString() : "0" + _position.inSeconds.toString()) : "00", style: TextStyle(color: Colors.white, fontSize: 18),),
                                            Text(" / ", style: TextStyle(color: Colors.white, fontSize: 18),),
                                            Text(_duration != null ? _duration.inMinutes.toString() : "0", style: TextStyle(color: Colors.white, fontSize: 18),),
                                            Text(":", style: TextStyle(color: Colors.white, fontSize: 18),),
                                            Text(_duration != null ? (_duration.inSeconds >= 10 ? _duration.inSeconds.toString() : "0" + _duration.inSeconds.toString()) : "00", style: TextStyle(color: Colors.white, fontSize: 18),),
                                          ],
                                        ),
                                      ),
                                      Container(
                                          margin: _videoPlayerController.value.aspectRatio >= 1.5 ? EdgeInsets.only(bottom: 10, right: 10,) : EdgeInsets.only(right: 10),
                                          child: IconButton(
                                            icon: Icon(Icons.fullscreen_exit),
                                            color: Colors.white,
                                            iconSize: 30,
                                            onPressed: (){
                                              Navigator.pop(context);
                                            },
                                          )
                                      )
                                    ],
                                  )
                              ),
                            )
                        ),
                      ],
                    ),
                  )
              )
          )
      ),
    );
  }
}

class VideoScene extends State<VideoState>  with SingleTickerProviderStateMixin {
  VideoPlayerController _videoPlayerController;
  Future<void> _initializeVideoPlayerFuture;
  Icon playIcon = Icon(Icons.play_arrow, color: Colors.white, size: 30,);
  String videoName;
  bool _isPlaying = false;
  Duration _duration = Duration(seconds: 0);
  Duration _position = Duration(seconds: 0);
  bool _isEnd = false, isShow = true, isFullScreen = false;
  AnimationController controller_true;
  Animation fadeOutAnimation;
  int rotateCorner = 0;
  double aspectRatio = 16/9;
  var connectivityResult;
  bool isExpanded, isDisposed = false;
  double mOpacity = 1.0, circularOpacity = 0.0, videoOpacity = 1.0;
  VideoScene(this.videoName, this.isExpanded);

  @override
  void initState() {
    print("Init video");
    isDisposed = false;
    controller_true = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500)
    );

    fadeOutAnimation = Tween(
        begin: 1.0,
        end: 0.0
    ).animate(controller_true);

    if(isExpanded == true) loadVideo();

    super.initState();
  }

  void loadVideo(){
    try{
      _videoPlayerController = VideoPlayerController.network('http://dobe.capnuoctrungan.vn/Content/Videos/' + videoName)..addListener(() {
        final bool isPlaying = _videoPlayerController.value.isPlaying;
        if (isPlaying != _isPlaying) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }
        Timer.run(() {
          if(isDisposed == false){
            this.setState((){
              _position = _videoPlayerController.value.position;
            });
          }
        });
        if(isDisposed == false){
          setState(() {
            _duration = _videoPlayerController.value.duration;
          });
        }
        if(isDisposed == false){
          _duration?.compareTo(_position) == 0 || _duration?.compareTo(_position) == -1 ? this.setState((){
            _isEnd = true;
            playIcon = Icon(Icons.play_arrow, color: Colors.white, size: 30);
          }) : this.setState((){
            _isEnd = false;
          });
        }
      });
    }
    catch(e){

    }
    _videoPlayerController.setLooping(true);
    _initializeVideoPlayerFuture = _videoPlayerController.initialize();
  }

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
    _videoPlayerController.dispose();
  }

  void seekToSecond(int second){
    Duration newDuration = Duration(seconds: second);
    _videoPlayerController.seekTo(newDuration);
  }

  void checkConnection() async {
    connectivityResult = await (Connectivity().checkConnectivity());
  }

  @override
  Widget build(BuildContext context) {
    checkConnection();

    // TODO: implement build
    if(connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi){
      return FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done)
          {
            if(_videoPlayerController.value.duration != null){
              if(_videoPlayerController.value.duration > Duration(seconds: 0)) return Container(
                  width: double.infinity,
                  child: AspectRatio(
                      aspectRatio: aspectRatio,
                      // Use the VideoPlayer widget to display the video.
                      child: GestureDetector(
                          onTap: (){
                            if(isShow == false){
                              controller_true.reverse();
                              isShow = true;
                            }
                            else{
                              controller_true.forward();
                              isShow = false;
                            }
                            setState(() {
                              checkConnection();
                              if(connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi){
                                if(_videoPlayerController.value.isPlaying){
                                  playIcon = Icon(Icons.play_arrow, color: Colors.white, size: 30);
                                  _videoPlayerController.pause();
                                }
                                else {
                                  playIcon = Icon(Icons.pause, color: Colors.white, size: 30);
                                  _videoPlayerController.play();
                                  isShow = false;
                                  controller_true.forward();
                                }
                              }
                            });
                          },
                          onDoubleTap: (){
                            setState(() async {
                              await Navigator.of(context).push(new MaterialPageRoute<Null>(
                                  builder: (BuildContext context) {
                                    return videoScreenScene(_videoPlayerController, _position, _duration, playIcon);
                                  },
                                  fullscreenDialog: true
                              ));

                              if(_videoPlayerController.value.isPlaying){
                                playIcon = Icon(Icons.pause, color: Colors.white, size: 30);
                              }
                              else {
                                playIcon = Icon(Icons.play_arrow, color: Colors.white, size: 30);
                              }
                            });
                          },
                          child: RotatedBox(
                            quarterTurns: rotateCorner,
                            child: Stack(
                              children: <Widget>[
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.black,
                                ),
                                Center(
                                  child: AspectRatio(
                                    aspectRatio: _videoPlayerController.value.aspectRatio,
                                    child: VideoPlayer(_videoPlayerController),
                                  ),
                                ),
                                Align(
                                    alignment: Alignment.bottomLeft,
                                    child: FadeTransition(
                                      opacity: fadeOutAnimation,
                                      child: Container(
                                          color: Colors.black54,
                                          child: Row(
                                            children: <Widget>[
                                              Container(
                                                margin: EdgeInsets.all(0),
                                                child: IconButton(
                                                  icon: playIcon,
                                                  onPressed: (){
                                                    setState(() {
                                                      checkConnection();
                                                      if(connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi){
                                                        if(_videoPlayerController.value.isPlaying){
                                                          playIcon = Icon(Icons.play_arrow, color: Colors.white, size: 30);
                                                          _videoPlayerController.pause();
                                                        }
                                                        else {
                                                          playIcon = Icon(Icons.pause, color: Colors.white, size: 30);
                                                          _videoPlayerController.play();
                                                          isShow = false;
                                                          controller_true.forward();
                                                        }
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                              Expanded(
                                                  child: Container(
                                                    height: 30,
                                                    child: Slider(
                                                      activeColor: Colors.red,
                                                      inactiveColor: Colors.white,
                                                      value: _position != null ? _position.inSeconds.toDouble() : 0,
                                                      min: 0.0,
                                                      max: _duration != null ? _duration.inSeconds.toDouble() : 0,
                                                      onChanged: (double value){
                                                        setState(() {
                                                          seekToSecond(value.toInt());
                                                          value = value;
                                                          _videoPlayerController.play();
                                                          playIcon = Icon(Icons.pause, color: Colors.white, size: 30);
                                                        });
                                                      },
                                                    ),
                                                  )
                                              ),
                                              Container(
                                                margin: EdgeInsets.only(right: 10),
                                                child: Row(
                                                  children: <Widget>[
                                                    Text(_position != null ? _position.inMinutes.toString() : "0", style: TextStyle(color: Colors.white),),
                                                    Text(":", style: TextStyle(color: Colors.white),),
                                                    Text(_position != null ? (_position.inSeconds >= 10 ? _position.inSeconds.toString() : "0" + _position.inSeconds.toString()) : "00", style: TextStyle(color: Colors.white),),
                                                    Text(" / ", style: TextStyle(color: Colors.white),),
                                                    Text(_duration != null ? _duration.inMinutes.toString() : "0", style: TextStyle(color: Colors.white),),
                                                    Text(":", style: TextStyle(color: Colors.white),),
                                                    Text(_duration != null ? (_duration.inSeconds >= 10 ? _duration.inSeconds.toString() : "0" + _duration.inSeconds.toString()) : "00", style: TextStyle(color: Colors.white),),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                  margin: EdgeInsets.only(right: 10),
                                                  child: IconButton(
                                                    icon: Icon(Icons.fullscreen),
                                                    color: Colors.white,
                                                    iconSize: 30,
                                                    onPressed: (){
                                                      setState(() async {
                                                        await Navigator.of(context).push(new MaterialPageRoute<Null>(
                                                            builder: (BuildContext context) {
                                                              return videoScreenScene(_videoPlayerController, _position, _duration, playIcon);
                                                            },
                                                            fullscreenDialog: true
                                                        ));

                                                        if(_videoPlayerController.value.isPlaying){
                                                          playIcon = Icon(Icons.pause, color: Colors.white, size: 30);
                                                        }
                                                        else {
                                                          playIcon = Icon(Icons.play_arrow, color: Colors.white, size: 30);
                                                        }
                                                      });
                                                    },
                                                  )
                                              )
                                            ],
                                          )
                                      ),
                                    )
                                ),
                              ],
                            ),
                          )
                      )
                  )
              );
              else return Container(
                  width: double.infinity,
                  color: Colors.black,
                  margin: EdgeInsets.only(bottom: 20, top: 10),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Center(child: Text("Error loading video", style: TextStyle(color: Colors.white),)),
                  )
              );
            }
            else return Container(
                width: double.infinity,
                color: Colors.black,
                margin: EdgeInsets.only(bottom: 20, top: 10),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Center(child: Text("Error loading video", style: TextStyle(color: Colors.white),)),
                )
            );
          }
          else if (snapshot.connectionState == ConnectionState.waiting) {
            // If the VideoPlayerController is still initializing, show a
            // loading spinner.
            return Container(
              margin: EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          else {
            return Container(
                width: double.infinity,
                color: Colors.black,
                margin: EdgeInsets.only(bottom: 20, top: 10),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Center(child: Text("Error loading video", style: TextStyle(color: Colors.white),)),
                )
            );
          }
        },
      );
    }
    else{
      return Stack(
        children: <Widget>[
          Opacity(
            opacity: circularOpacity,
            child: Container(
              margin: EdgeInsets.only(bottom: 20, top: 10),
              height: 77,
              color: Colors.black,
              width: double.infinity,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          Opacity(
            opacity: mOpacity,
            child: Container(
                width: double.infinity,
                color: Colors.black,
                margin: EdgeInsets.only(bottom: 20, top: 10),
                child: Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: <Widget>[
                        RaisedButton.icon(
                            onPressed: (){
                              setState(() {
                                mOpacity = 0.0;
                                circularOpacity = 1.0;
                                checkConnection();
                                loadVideo();
                                Future.delayed(const Duration(seconds: 1),(){
                                  setState(() {
                                    mOpacity = 1.0;
                                    circularOpacity = 0.0;
                                  });
                                });
                              });
                            },
                            color: Colors.black,
                            elevation: 0,
                            icon: Icon(Icons.refresh, color: Colors.white,),
                            label: Text("Reload", style: TextStyle(color: Colors.white),)
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 10, right: 10),
                          child: Center(child: Text("Enable wifi or mobile data to view this video", style: TextStyle(color: Colors.white),)),
                        )
                      ],
                    )
                )
            ),
          )
        ],
      );
    }
  }
}