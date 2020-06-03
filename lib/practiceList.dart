import 'dart:convert';
import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart';
import 'questionsModel.dart';
import 'translations.dart';
import 'VideoPlayer.dart';
import 'package:connectivity/connectivity.dart';

Color rowColor = Colors.white;
String total, real , fake, real_name;
List<String> false_name = new List<String>();
List<String> standard_name = new List<String>();
List<AudioPlayer> list_playing = new List<AudioPlayer>();

class practiceList extends StatefulWidget{
  BuildContext mContext;

  practiceList(this.mContext);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return practiceListScene(mContext);
  }
}

class practiceListScene extends State<practiceList>{
  List<questionsModel> trueSoundList, falseSoundList, standardSoundList;
  List<dynamic> myData;
  Color titleColor = Colors.black54, buttonColor = Colors.green, durationColor = Colors.black54;
  BuildContext mContext;
  practiceListScene(this.mContext);
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    trueSoundList = new List<questionsModel>();
    falseSoundList = new List<questionsModel>();
    standardSoundList = new List<questionsModel>();
  }

  void showSnackBar(){
    scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(Translations.of(context).text('practice_instruction')),
          duration: Duration(seconds: 5),
        )
    );
  }

  Future loadQuestions() async {
    await loadQuestionTrue();
    await loadQuestionFalse();
    await loadQuestionStandard();
    return;
  }

  Future<String> loadJsonTrue() async {
    return await DefaultAssetBundle.of(context).loadString("questions/questions_list_true.json");
  }

  Future<String> loadJsonFalse() async {
    return await DefaultAssetBundle.of(context).loadString("questions/questions_list_false.json");
  }

  Future<String> loadJsonStandard() async {
    return await DefaultAssetBundle.of(context).loadString("questions/questions_list_standard.json");
  }

  void loadQuestionTrue() async {
    trueSoundList.clear();
    String temp = await loadJsonTrue();
    myData = json.decode(temp);
    for(int i = 0; i < myData.length; i++){ //replace 5 by numbOfTrue when use
      questionsModel tempQuestion = new questionsModel(myData[i]["question_name"].toString(), myData[i]["answer"].toString());
      trueSoundList.add(tempQuestion);
    }
  }

  void loadQuestionFalse() async {
    falseSoundList.clear();
    false_name.clear();
    String temp = await loadJsonFalse();
    myData = json.decode(temp);
    for(int i = 0; i < myData.length; i++){ //replace 5 by numbOfTrue when use
      questionsModel tempQuestion = new questionsModel(myData[i]["question_name"].toString(), myData[i]["answer"].toString());
      falseSoundList.add(tempQuestion);
      false_name.add(Translations.of(context).text("false/" + myData[i]["question_name"]));
    }
  }

  void loadQuestionStandard() async {
    standardSoundList.clear();
    standard_name.clear();
    String temp = await loadJsonStandard();
    myData = json.decode(temp);
    for(int i = 0; i < myData.length; i++){ //replace 5 by numbOfTrue when use
      questionsModel tempQuestion = new questionsModel(myData[i]["question_name"].toString(), myData[i]["answer"].toString());
      standardSoundList.add(tempQuestion);
      standard_name.add(Translations.of(context).text("standard/" + myData[i]["question_name"]));
    }
  }

  @override
  Widget build(BuildContext context) {
    total = Translations.of(context).text('practice_water_total');
    real = Translations.of(context).text('practice_water_real');
    fake = Translations.of(context).text('practice_water_fake');
    real_name = Translations.of(context).text('practice_real_name');
    // TODO: implement build
    return MediaQuery.removePadding(
      context: context,
      child: DefaultTabController(
          length: 3,
          child: FutureBuilder(
            future: loadQuestions(),
            builder: (context, snapshot){
              if(snapshot.connectionState == ConnectionState.done) {
                return Scaffold(
                  key: scaffoldKey,
                  appBar: AppBar(
                    title: Text(Translations.of(context).text('practice_title')),
                    backgroundColor: Colors.cyan,
                    bottom: TabBar(
                      isScrollable: true,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      indicatorPadding: EdgeInsets.only(left: 20, right: 20),
                      unselectedLabelStyle: TextStyle(fontSize: 12),
                      tabs: <Widget>[
                        Tab(
                          child: Column(
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(bottom: 5),
                                child: Text(Translations.of(context).text('practice_bar_standard')),
                              ),
                              Text(total + standardSoundList.length.toString()),
                            ],
                          ),
                        ),
                        Tab(
                          child: Column(
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(bottom: 5),
                                child: Text(Translations.of(context).text('practice_bar_leakage')),
                              ),
                              Text(total + trueSoundList.length.toString()),
                            ],
                          ),
                        ),
                        Tab(
                          child: Column(
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(bottom: 5),
                                child: Text(Translations.of(context).text('practice_bar_fake')),
                              ),
                              Text(total + falseSoundList.length.toString()),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  body: Builder(
                    builder: (context) => tabBarWidget(context),
                  )
              );
              }
              else return Container(
                height: double.infinity,
                width: double.infinity,
                color: Colors.white,
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            },
          )
      ),
      removeTop: true,
    );
  }

  Widget tabBarWidget(BuildContext context){
    WidgetsBinding.instance.addPostFrameCallback((_){
      Scaffold.of(context).showSnackBar(
          SnackBar(
            content: Text(Translations.of(context).text('practice_instruction')),
            duration: Duration(seconds: 5),
          )
      );
    });
    return TabBarView(
      children: <Widget>[
        ListView(
          children: <Widget>[
            standardSoundListView()
          ],
        ),
        ListView(
          children: <Widget>[
            trueSoundListView()
          ],
        ),
        ListView(
          children: <Widget>[
            falseSoundListView()
          ],
        ),
      ],
    );
  }

  Widget trueSoundListView() {
    return ExpansionContentTrueScene(trueSoundList, context, buttonColor, durationColor);
  }

  Widget falseSoundListView() {
    return ExpansionContentFalse(falseSoundList, context, buttonColor, durationColor);
  }

  Widget standardSoundListView() {
    return ExpansionContentStandard(standardSoundList, context, buttonColor, durationColor);
  }
}

class ExpansionContentTrueScene extends StatefulWidget {
  List<questionsModel> trueSoundList;
  BuildContext context;
  Color titleColor, buttonColor, durationColor;
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return ExpansionContentTrue(trueSoundList, context, buttonColor, durationColor);
  }

  ExpansionContentTrueScene(this.trueSoundList, this.context, this.buttonColor,
      this.durationColor);
}

class ExpansionContentTrue extends State<ExpansionContentTrueScene>{
  List<questionsModel> trueSoundList;
  BuildContext context;
  ExpansionContentTrue(this.trueSoundList, this.context, this.buttonColor, this.durationColor);
  Color titleColor, buttonColor, durationColor;
  bool isExpanded = false;


  @override
  void initState() {
    super.initState();
  }

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
                        onExpansionChanged: (e){
                          setState(() {
                            if(e == true){
                              isExpanded = true;
                            }
                            else isExpanded = false;
                          });
                        },
                        children: <Widget>[
                          Image.asset("images/true/" + sound[i].filePath.substring(0,sound[i].filePath.length-3) + "jpg"),
                          Container(
                            margin: EdgeInsets.only(top: 10),
                            child: VideoState(sound[i].filePath.substring(0,sound[i].filePath.length-3) + "mp4", isExpanded),
                          )
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
        height: MediaQuery.of(context).size.height - 100,
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
        height: MediaQuery.of(context).size.height - 100,
        child: ListView(
          children: _buildExpandableContent(falseSoundList, "Fake sound"),
        )
    );
  }
  ExpansionContentFalse(this.falseSoundList, this.context, this.buttonColor, this.durationColor);
}

class ExpansionContentStandard extends StatelessWidget {
  List<questionsModel> standardSoundList;
  BuildContext context;
  ExpansionContentStandard(this.standardSoundList, this.context, this.buttonColor, this.durationColor);
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
                                child: Text(standard_name.elementAt(i), style: TextStyle(fontSize: 14),)
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: audioWidget("standard/" + sound[i].filePath, buttonColor, durationColor),
                            )
                          ],
                        ),
                        children: <Widget>[
                          Image.asset("images/standard/" + sound[i].filePath.substring(0,sound[i].filePath.length-3) + "jpg")
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
        height: MediaQuery.of(context).size.height - 100,
        child: ListView(
          children: _buildExpandableContent(standardSoundList, real_name),
        )
    );
  }
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



