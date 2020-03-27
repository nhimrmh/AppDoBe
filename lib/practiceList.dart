import 'dart:convert';
import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart';
import 'questionsModel.dart';
import 'translations.dart';

Color rowColor = Colors.white;
String total, real , fake, real_name;
List<String> false_name = new List<String>();
List<AudioPlayer> list_playing = new List<AudioPlayer>();

class practiceList extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return practiceListScene();
  }
}

class practiceListScene extends State<practiceList>{
  List<questionsModel> trueSoundList;
  List<questionsModel> falseSoundList;
  List<dynamic> myData;
  double heightTrue, heightFalse;
  bool isExpandedFalse = false, isExpandedTrue = false;
  Color titleColor = Colors.black54, buttonColor = Colors.green, durationColor = Colors.black54;

  @override
  void initState() {
    super.initState();
    trueSoundList = new List<questionsModel>();
    falseSoundList = new List<questionsModel>();
    loadQuestionTrue();
    loadQuestionFalse();
  }

  Future<String> loadJsonTrue() async {
    return await DefaultAssetBundle.of(context).loadString("questions/questions_list_true.json");
  }

  Future<String> loadJsonFalse() async {
    return await DefaultAssetBundle.of(context).loadString("questions/questions_list_false.json");
  }

  void loadQuestionTrue() async {
    String temp = await loadJsonTrue();
    myData = json.decode(temp);
    for(int i = 0; i < myData.length; i++){ //replace 5 by numbOfTrue when use
      questionsModel tempQuestion = new questionsModel(myData[i]["question_name"].toString(), myData[i]["answer"].toString());
      trueSoundList.add(tempQuestion);
    }
  }

  void loadQuestionFalse() async {
    String temp = await loadJsonFalse();
    myData = json.decode(temp);
    for(int i = 0; i < myData.length; i++){ //replace 5 by numbOfTrue when use
      questionsModel tempQuestion = new questionsModel(myData[i]["question_name"].toString(), myData[i]["answer"].toString());
      falseSoundList.add(tempQuestion);
      false_name.add(Translations.of(context).text("false/" + myData[i]["question_name"]));
    }
  }

  @override
  Widget build(BuildContext context) {
    total = Translations.of(context).text('practice_water_total');
    real = Translations.of(context).text('practice_water_real');
    fake = Translations.of(context).text('practice_water_fake');
    real_name = Translations.of(context).text('practice_real_name');
    // TODO: implement build
    return new MaterialApp(
      supportedLocales: [
        Locale('en'),
        Locale('vn'),
      ],
      home: new Scaffold(
          appBar: AppBar(title: Text(Translations.of(context).text('app_bar_practice')),),
          body: ListView(
            children: <Widget>[
              Column(
                children: <Widget>[
                  FutureBuilder(
                    future: loadJsonTrue(),
                    builder: (context, snapshot){
                      if(snapshot.connectionState == ConnectionState.done) return trueSoundListView();
                      else return CircularProgressIndicator();
                    },
                  ),
                  FutureBuilder(
                    future: loadJsonFalse(),
                    builder: (context, snapshot){
                      if(snapshot.connectionState == ConnectionState.done) return falseSoundListView();
                      else return CircularProgressIndicator();
                    },
                  )
                ],
              ),
            ],
          )
      )
    );
  }

  void _trueExpansionChanged(bool ixExpanded){
    if(ixExpanded){
      setState(() {
        isExpandedFalse = false;
        isExpandedTrue = true;
      });
    }
    else{

    }
  }

  void _falseExpansionChanged(bool ixExpanded){
    if(ixExpanded){
      setState(() {
        isExpandedFalse = true;
        isExpandedTrue = false;
      });
    }
    else{

    }
  }

  Widget trueSoundListView() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: 1,
            itemBuilder: (context, i) {
              return new Container(
                child: ExpansionTile(
                  initiallyExpanded : isExpandedTrue,
                  onExpansionChanged: _trueExpansionChanged,
                  subtitle: Text(total + trueSoundList.length.toString(), style: TextStyle(fontSize: 14),),
                  title: Text(real, style: TextStyle(fontSize: 16),),
                  children: <Widget>[
                    new ExpansionContentTrue(trueSoundList, heightTrue, context, buttonColor, durationColor),
                  ],
                )
              );
            },
          ),
        ],
      ),
    );
  }

  Widget falseSoundListView() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: 1,
            itemBuilder: (context, i) {
              return new ExpansionTile(
                initiallyExpanded : isExpandedFalse,
                onExpansionChanged: _falseExpansionChanged,
                subtitle: Text(total + falseSoundList.length.toString(), style: TextStyle(fontSize: 14),),
                title: Text(fake, style: TextStyle(fontSize: 16),),
                children: <Widget> [
                  new ExpansionContentFalse(falseSoundList, heightFalse, context, buttonColor, durationColor),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ExpansionContentTrue extends StatelessWidget {
  List<questionsModel> trueSoundList;
  double heightTrue;
  BuildContext context;
  ExpansionContentTrue(this.trueSoundList, this.heightTrue, this.context, this.buttonColor, this.durationColor);
  Color titleColor, buttonColor, durationColor;

  _buildExpandableContent(List<questionsModel> sound, String name){
    List<Widget> columnContent = [];
    for(int i = 0; i < sound.length; i++){
      columnContent.add(
          new Container(
              width: MediaQuery.of(context).size.width,
              child: ListTile(
                  title: Container(
                    color: rowColor,
                    child: ExpansionTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Expanded(
                            child: Text(name + " " + (i + 1).toString(), style: TextStyle(color: titleColor, fontSize: 14),),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: audioWidget("true/" + sound[i].filePath, buttonColor, durationColor),
                          )
                        ],
                      ),
                      children: <Widget>[
                        Image.asset("images/true/" + sound[i].filePath.substring(0,sound[i].filePath.length-3) + "jpg")
                      ],
                    )
                  )
              )
          )
      );
    }
    return columnContent;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
        height: MediaQuery.of(context).size.height - 2*85 - 55,
        child: ListView(
          children: _buildExpandableContent(trueSoundList, real_name),
        )
    );
  }
}

class ExpansionContentFalse extends StatelessWidget {
  _buildExpandableContent(List<questionsModel> sound, String name){
    List<Widget> columnContent = [];
    for(int i = 0; i < sound.length; i++){
      columnContent.add(
          new Container(
              width: MediaQuery.of(context).size.width,
              child: ListTile(
                  title: Container(
                    color: rowColor,
                    child: ExpansionTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Expanded(
                            child: Text(false_name.elementAt(i), style: TextStyle(fontSize: 14),)
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: audioWidget("false/" + sound[i].filePath, buttonColor, durationColor),
                          )
                        ],
                      ),
                      children: <Widget>[
                        Image.asset("images/false/" + sound[i].filePath.substring(0,sound[i].filePath.length-3) + "jpg")
                      ],
                    )
                  )
              )
          )
      );
    }
    return columnContent;
  }
  List<questionsModel> falseSoundList;
  double heightFalse;
  BuildContext context;
  Color buttonColor, durationColor;
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
        height: MediaQuery.of(context).size.height - 2*85 - 55,
        child: ListView(
          children: _buildExpandableContent(falseSoundList, "Fake sound"),
        )
    );
  }
  ExpansionContentFalse(this.falseSoundList, this.heightFalse, this.context, this.buttonColor, this.durationColor);
}

class audioWidget extends StatefulWidget {
  String filePath;
  Color buttonColor, durationColor;
  audioWidget(this.filePath, this.buttonColor, this.durationColor);

  @override
  audioWidgetScene createState() => audioWidgetScene(filePath);
}

class audioWidgetScene extends State<audioWidget> {
  String filePath;
  AudioCache audioCache = AudioCache();
  AudioPlayer audioPlayer = AudioPlayer();
  Duration duration = Duration();
  Duration position = Duration();
  bool isPlaying = false, isDisposed = false, isDisable = false, isInitial = true;
  AudioPlayerState playerState;
  IconData iconAudio = Icons.play_arrow;
  Color buttonColor = Colors.green;

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

  audioWidgetScene(this.filePath);

}



