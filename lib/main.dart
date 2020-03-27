import 'dart:convert';
import 'dart:io';

import 'package:appdobe/HistoryFile.dart';
import 'package:appdobe/pointJson.dart';
import 'package:appdobe/practiceList.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:country_code_picker/country_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'translations.dart';
import 'Application.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'questionsModel.dart';
import 'showDialog.dart';
import 'LocalFile.dart';
import 'resultModel.dart';
import 'package:flutter_sparkline/flutter_sparkline.dart';
import 'dart:convert'; //to convert json to maps and vice versa
import 'package:shimmer/shimmer.dart';
import 'package:charts_flutter/flutter.dart' as charts;

String data;
String history;

File jsonFile;
Directory dir;
String fileName = "history.json";
bool fileExists = false;
List<Map<String, dynamic>> fileContent;
List<double> listScores = [];
List<charts.Series<Task,String>> _seriesPieDataBad = new List<charts.Series<Task,String>>();
List<charts.Series<Task,String>> _seriesPieDataGood = new List<charts.Series<Task,String>>();

var badData = [
  new Task('Your Score', 33.5, Colors.red),
  new Task('All', 65.5, Colors.white)
];
var goodData = [
  new Task('Your Score', 33.5, Colors.red),
  new Task('All', 65.5, Colors.white)
];

_generateData_bad(){
  badData.clear();
  int count_bad = listScores.where((q) => q < 5).toList().length;
  int bad_por = ((count_bad / listScores.length)*100).round();
  int all_por = 100 - bad_por;
  Task temp = new Task("Bad score", double.parse(bad_por.toString()), Colors.red);
  Task all = new Task("All", double.parse(all_por.toString()), Colors.white);
  badData.add(temp);
  badData.add(all);

  _seriesPieDataBad.add(
      charts.Series(
          data: badData,
          domainFn: (Task task,_) => task.task,
          measureFn: (Task task,_) => task.taskValue,
          colorFn: (Task task,_) => charts.ColorUtil.fromDartColor(task.taskColor),
          id: 'Daily Task',
          labelAccessorFn: (Task row,_) => '${row.taskValue}'
      )
  );
}

_generateData_good(){
  goodData.clear();
  int count_good = listScores.where((q) => q >= 5).toList().length;
  int bad_por = ((count_good / listScores.length)*100).round();
  int all_por = 100 - bad_por;
  Task temp = new Task("Bad score", double.parse(bad_por.toString()), Colors.green);
  Task all = new Task("All", double.parse(all_por.toString()), Colors.white);
  goodData.add(temp);
  goodData.add(all);

  _seriesPieDataGood.add(
      charts.Series(
          data: goodData,
          domainFn: (Task task,_) => task.task,
          measureFn: (Task task,_) => task.taskValue,
          colorFn: (Task task,_) => charts.ColorUtil.fromDartColor(task.taskColor),
          id: 'Daily Task',
          labelAccessorFn: (Task row,_) => '${row.taskValue}'
      )
  );
}

void main() => runApp(MyApp());

void writeScore(int trueCount, int falseCount){
  print("Write data");
  LocalFile.readContent().then((String value) {
    data = value;
  });
  if(data == null || data == "") LocalFile.writeContent(trueCount.toString() + "%1*" + trueCount.toString());
  else{
    if(data.indexOf("%") == -1 || data.indexOf("*") == -1) LocalFile.writeContent("0%0*0");
    LocalFile.readContent().then((String value) {
      data = value;
    });
    int firstSign = data.indexOf("%");
    int secondSign = data.indexOf("*");
    double averageScore = double.parse(data.substring(0, firstSign));
    int numberTime = int.parse(data.substring(firstSign+1, secondSign));
    if(numberTime > 0) LocalFile.writeContent(((averageScore*numberTime + trueCount)/(numberTime + 1)).toString() + "%" + (numberTime+1).toString() + "*" + trueCount.toString());
    else LocalFile.writeContent(trueCount.toString() + "%1*" + trueCount.toString());
  }
}

Future readHistory() async {
  listScores.clear();
  await getApplicationDocumentsDirectory().then((Directory directory) {
    dir = directory;
    jsonFile = new File(dir.path + "/" + fileName);
    fileExists = jsonFile.existsSync();
    if(fileExists) {
      print("File exist");
      var temp = json.decode(jsonFile.readAsStringSync());
      if(temp.length > 1) {
        print("Size > 1");
        for (int i = 0; i < temp.length; i++) {
          print(temp.toString());
          listScores.add(double.parse(temp[i]["score"]));
        }
      }
      else if(temp.length == 1){
        listScores.add(double.parse(temp["score"]));
      }
      else{
        listScores.add(0);
      }
    }
    else{
      print("File not exist");
      listScores.add(0);
    }
  });
  return;
}

void writeHistory(int score){
  writeToFile(score.toDouble());
}

void createFile(Map<String, String> content, String fileName) {
  print("Creating file!");
  File file = new File(dir.path + "/" + fileName);
  file.createSync();
  fileExists = true;
  file.writeAsStringSync(json.encode(content));
}

void writeToFile(double value) {
  var list = [];
  getApplicationDocumentsDirectory().then((Directory directory) {
    dir = directory;
    fileExists = jsonFile.existsSync();
    print("Writing to file!");
    Map<String, String> content = {"score": value.toString()};
    if (fileExists) {
      print("File exists");
      var temp = json.decode(jsonFile.readAsStringSync());
      if(temp.length > 1) {
        temp.add(content);
        jsonFile.writeAsStringSync(json.encode(temp));
      }
      else {
        list.add(temp);
        list.add(content);
        jsonFile.writeAsStringSync(json.encode(list));
      }
      //jsonFileContent.addAll(content);
    } else {
      print("File does not exist!");
      createFile(content, fileName);
    }
    fileContent = json.decode(jsonFile.readAsStringSync());
    print(fileContent);
  });
}

class MyApp extends StatefulWidget {
  @override
  _PickLanguage createState() => new _PickLanguage();
}

Future delaySplash() async {
  await Future.delayed(const Duration(milliseconds: 8000), (){
    return;
  });
}

Future delayShimmer() async {
  await Future.delayed(const Duration(milliseconds: 4700), (){
    return;
  });
}

class _PickLanguage extends State<MyApp> with SingleTickerProviderStateMixin{

  AnimationController controller;
  Animation fadeInAnimation;

  SpecificLocalizationDelegate _localeOverrideDelegate;
  @override
  void initState() {
    super.initState();
    _localeOverrideDelegate = new SpecificLocalizationDelegate(null);
    applic.onLocaleChanged = onLocaleChange;

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    fadeInAnimation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(controller);

  }

  onLocaleChange(Locale locale){
    setState((){
      _localeOverrideDelegate = new SpecificLocalizationDelegate(locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    controller.forward();
    return new MaterialApp(
      supportedLocales: applic.supportedLocales(),
      localizationsDelegates: [
        _localeOverrideDelegate,
        const TranslationsDelegate(),
        CountryLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      home: Builder(
          builder: (context) => Scaffold(
              body: Container(
                child: FutureBuilder(
                  future: delaySplash(),
                  builder: (context, snapshot){
                    if(snapshot.connectionState == ConnectionState.done){
                      return Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(left: 30, right: 30),
                              child: Container(
                                margin: EdgeInsets.only(top: 3),
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      margin: const EdgeInsets.only(left: 10.0, right: 10.0, top: 20),
                                      child: Text(
                                        Translations.of(context).text('pick_language'),
                                        style: TextStyle(
                                          //fontFamily: 'Montserrat',
                                          fontSize: 18,
                                          //fontWeight: FontWeight.w900
                                        ),),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        new GestureDetector(
                                          onTap: (){
                                            applic.onLocaleChanged(new Locale('vn',''));
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(top: 25.0, left: 10.0, right: 10.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                                SizedBox(
                                                  width: 60,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(right: 15.0),
                                                    child: Image.asset('vn.png'),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 110,
                                                  child: Text(
                                                    Translations.of(context).text('pick_language_op_1'),
                                                    style: TextStyle(
                                                      //fontFamily: 'Monserrat',
                                                        fontSize: 17,
                                                        fontWeight: FontWeight.w500
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        new GestureDetector(
                                          onTap: (){
                                            applic.onLocaleChanged(new Locale('en',''));
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(top: 20.0, left: 10.0, right: 10.0, bottom: 25.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                                SizedBox(
                                                  width: 60,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(right: 15.0),
                                                    child: Image.asset('us.png'),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 110,
                                                  child: Text(
                                                    Translations.of(context).text('pick_language_op_2'),
                                                    style: TextStyle(
                                                      //fontFamily: 'Monserrat',
                                                        fontSize: 17,
                                                        fontWeight: FontWeight.w500
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                                          width: double.infinity,
                                          child: RaisedButton.icon(
                                            onPressed: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => _PickCountry()));
                                            },
                                            elevation: 5.0,
                                            icon: Icon(
                                              Icons.navigate_next,
                                              color: Colors.white,
                                            ),
                                            label: Text(
                                              Translations.of(context).text('next'),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  //border: Border.all(width: 2, color: Colors.grey),
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(20.0)
                                  ),
                                ),
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(20.0)
                                ),
                                gradient: LinearGradient(
                                    colors: [Colors.cyan, Colors.blue[700]]
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 2,
                                      spreadRadius: 0,
                                      offset: Offset(
                                          2,
                                          2
                                      )
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.cyanAccent, Colors.blue]
                            )
                        ),
                      );
                    }
                    else{
                      return FutureBuilder(
                        future: delayShimmer(),
                        builder: (context, snapshot){
                          if(snapshot.connectionState == ConnectionState.done){
                            return Center(
                              child: Container(
                                  width: double.infinity,
                                  child: FadeTransition(
                                      opacity: fadeInAnimation,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Container(
                                            width: MediaQuery.of(context).size.width/2.5,
                                            child: Image.asset("images/logo-3d-metal.png"),
                                          ),
                                          Container(
                                              margin: EdgeInsets.only(top: 10),
                                              child: ShaderMask(
                                                shaderCallback: (bounds) => LinearGradient(
                                                    colors: [Colors.blue[200], Colors.blue[700]],
                                                    tileMode: TileMode.mirror
                                                ).createShader(bounds),
                                                child: const Text("capnuoctrungan.vn", style: TextStyle(fontFamily: "Montserrat" ,fontSize: 25, color: Colors.white),),
                                              )
                                          )
                                        ],
                                      ),
                                  )
                              ),
                            );
                          }
                          else{
                            return Center(
                              child: Container(
                                  width: double.infinity,
                                  child: FadeTransition(
                                      opacity: fadeInAnimation,
                                      child: Shimmer.fromColors(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: <Widget>[
                                            Container(
                                              width: MediaQuery.of(context).size.width/2.5,
                                              child: Image.asset("images/logo-3d-metal.png"),
                                            ),
                                            Container(
                                                margin: EdgeInsets.only(top: 10),
                                                child: Text("capnuoctrungan.vn", style: TextStyle(fontFamily: "Montserrat" ,fontSize: 25, color: Colors.white),),
                                            )
                                          ],
                                        ),
                                        baseColor: Colors.blue[300],
                                        highlightColor: Colors.white,
                                        loop: 3,
                                      )
                                  )
                              ),
                            );
                          }
                        },
                      );
                    }
                  },
                ),
                //color: Colors.blueGrey[100],
              )
          )
      ),
    );
  }
}

class _PickCountry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      supportedLocales: [
        Locale('en'),
        Locale('vn'),
      ],
      home: new Scaffold(
        body: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 30, right: 30),
                child: Container(
                  margin: EdgeInsets.only(top: 3),
                  child: Column(
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.only(left: 10.0, right: 10.0, top: 20),
                        child: Text(
                          Translations.of(context).text('pick_country'),
                          style: TextStyle(
                            //fontFamily: 'Montserrat',
                            fontSize: 18,
                            //fontWeight: FontWeight.w900
                          ),),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CountryCodePicker(
                                  onChanged: print,
                                  initialSelection: 'VN',
                                  showCountryOnly: true,
                                  showOnlyCountryWhenClosed: true,
                                  favorite: ['+84', 'VN'],
                                  textStyle: TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                            width: double.infinity,
                            child: RaisedButton.icon(
                              onPressed: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => DropDownScreen()));
                              },
                              elevation: 5.0,
                              icon: Icon(
                                Icons.navigate_next,
                                color: Colors.white,
                              ),
                              label: Text(
                                Translations.of(context).text('next'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    //border: Border.all(width: 2, color: Colors.grey),
                    borderRadius: BorderRadius.all(
                        Radius.circular(20.0)
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.cyan, Colors.blue[700]]
                  ),
                  borderRadius: BorderRadius.all(
                      Radius.circular(20.0)
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        spreadRadius: 0,
                        offset: Offset(
                            2,
                            2
                        )
                    ),
                  ],
                ),
              )
            ],
          ),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.cyanAccent, Colors.blue]
              )
          ),
        )
      ),
    );
  }
}

class DropDownScreen extends StatefulWidget{
  @override
  State createState() => _MainScreen();

}

class _MainScreen extends State<DropDownScreen>{
  static int index = 0;
  String app_bar_main = "app_bar_main";
  static const String vn = 'Tiếng Việt';
  static const String en = 'English';

  static const List<String> choices = <String>[
    vn,
    en
  ];

  Future getData() async {
    await readHistory();
    _generateData_bad();
    _generateData_good();
  }

  @override
  void initState() {
    super.initState();
    index = 0;
    getData();
    LocalFile.readContent().then((String value) {
      setState(() {
        data = value;
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    String app_bar_name = Translations.of(context).text(app_bar_main);
    return new MaterialApp(
      supportedLocales: [
        Locale('en'),
        Locale('vn'),
      ],
      home: new Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          //backgroundColor: Colors.blue,
          currentIndex: index,
          onTap: (value) => setState(() {
            index = value;
            app_bar_main = (index == 0 ? "app_bar_main" : index == 1 ? "app_bar_tutorial" : "app_bar_info");
          }),
          items: [
            BottomNavigationBarItem(
                icon: new Icon(Icons.home),
                title: new Text(Translations.of(context).text('main_activity_home'))
            ),
            BottomNavigationBarItem(
                icon: new Icon(Icons.assignment),
                title: new Text(Translations.of(context).text('main_activity_tutorial'))
            ),
            BottomNavigationBarItem(
                icon: new Icon(Icons.info),
                title: new Text(Translations.of(context).text('main_activity_info'))
            ),
          ],
        ),
        body: new NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled){
            return <Widget>[
              new SliverAppBar(
                leading: Container(
                  transform: Matrix4.translationValues(8, 0, 0),
                  child: Image.asset("images/logo-3d-metal_small.png"),
                ),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.home, color: Colors.white,),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String choice){
                      if(choice == "English") applic.onLocaleChanged(new Locale('en',''));
                      else applic.onLocaleChanged(new Locale('vn',''));
                    },
                    itemBuilder: (BuildContext context){
                      return choices.map((String choice){
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(choice),
                        );
                      }).toList();
                    },
                  )
                ],
                title: Text(app_bar_name),
                pinned: false,
                snap: true,
                floating: true,
                forceElevated: innerBoxIsScrolled,
              )
            ];
          },
          body: _getBody(index),
        )
      ),
    );
  }

  Widget _getBody(int index){
    switch(index){
      case 0: return _mainPage();
      case 1: return _tutorialPage();
      case 2: return _infoPage();
      default: return _mainPage();
    }
  }

  _mainPage(){
    return ListView(
      children: <Widget>[
        Container(
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 0, top: 0),
                child: Column(
                  children: <Widget>[
                    Container(
                        margin: EdgeInsets.only(top: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(right: 5),
                              child: Icon(Icons.av_timer, color: Colors.blue[700]),
                            ),
                            Text("Overview", style: TextStyle(fontSize: 16, color: Colors.blue[700], fontWeight: FontWeight.w500),),
                          ],
                        )
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 5, bottom: 10),
                      child: Text("Look at your significant numbers here", style: TextStyle(fontSize: 12),),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 0, bottom: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Container(
                            child: Container(
                              margin: EdgeInsets.only(left: 0, top: 3),
                              width: MediaQuery.of(context).size.width/2.5,
                              //margin: EdgeInsets.only(top: 10),
                              child: Container(
                                margin: EdgeInsets.all(20),
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(top: 5, bottom: 5),
                                      child: Text(
                                        Translations.of(context).text('main_activity_last'),
                                        style: TextStyle(
                                          //fontFamily: "Montserrat",
                                            fontSize: 16,
                                            color: Colors.black
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(bottom: 0),
                                      child: Text(
                                        (data == null ? "0/10" : ((data.indexOf("*") != -1 && data.indexOf("%") != -1) ? ((data.substring(data.indexOf("*")+1, data.length)) + "/10") : "0/10")),
                                        style: TextStyle(
                                          //fontFamily: "Montserrat",
                                            fontSize: 40,
                                            color: data == null ? Colors.redAccent : (data.indexOf("*") != -1 && data.indexOf("%") != -1) ? ((int.parse((data.substring(data.indexOf("*")+1, data.length))) >= 5) ? Colors.green : Colors.redAccent) : Colors.redAccent
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                //border: Border.all(width: 2, color: Colors.grey),
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(5.0), topRight: Radius.circular(20.0), bottomLeft: Radius.circular(20.0), bottomRight: Radius.circular(5.0)
                                ),
                              ),
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [Colors.cyan, Colors.blue[700]]
                              ),
                              //border: Border.all(width: 2, color: Colors.grey),
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(5.0), topRight: Radius.circular(20.0), bottomLeft: Radius.circular(20.0), bottomRight: Radius.circular(5.0)
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 2,
                                    spreadRadius: 0,
                                    offset: Offset(
                                        2,
                                        2
                                    )
                                ),
                              ],
                            ),
                          ),
                          Container(
                            child: Container(
                              margin: EdgeInsets.only(left: 0, top: 3),
                              width: MediaQuery.of(context).size.width/2.5,
                              //margin: EdgeInsets.only(top: 10),
                              child: Container(
                                margin: EdgeInsets.all(20),
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(top: 5, bottom: 5),
                                      child: Text(
                                        Translations.of(context).text('main_activity_overall'),
                                        style: TextStyle(
                                          //fontFamily: "Montserrat",
                                            fontSize: 16,
                                            color: Colors.black
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(bottom: 0),
                                      child: Text(
                                        data == null ? "0" : ((data.indexOf("*") != -1 && data.indexOf("%") != -1) ? (data.substring(0, data.indexOf("%")).length > 4 ? (data.substring(0, 3) + (int.parse(data.substring(4, 5)) >= 5 ? ((int.parse(data.substring(3, 4)) + 1).toString().length == 1 ? (int.parse(data.substring(3, 4)) + 1).toString() : (int.parse(data.substring(3, 4)) + 1).toString().substring(0,1)) : data.substring(3, 4))) : data.substring(0, data.indexOf("%"))) : "0"),
                                        style: TextStyle(
                                          //fontFamily: "Montserrat",
                                            fontSize: 40,
                                            color: Colors.blue
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                //border: Border.all(width: 2, color: Colors.grey),
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(5.0), topRight: Radius.circular(20.0), bottomLeft: Radius.circular(20.0), bottomRight: Radius.circular(5.0)
                                ),
                              ),
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [Colors.cyan, Colors.blue[700]]
                              ),
                              //border: Border.all(width: 2, color: Colors.grey),
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(5.0), topRight: Radius.circular(20.0), bottomLeft: Radius.circular(20.0), bottomRight: Radius.circular(5.0)
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 2,
                                    spreadRadius: 0,
                                    offset: Offset(
                                        2,
                                        2
                                    )
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 0, bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Container(
                            child: Container(
                              margin: EdgeInsets.only(left: 0, top: 3),
                              //margin: EdgeInsets.only(top: 10),
                              child: Container(
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(top: 10, bottom: 5),
                                      child: Text(
                                        "Times play",
                                        style: TextStyle(
                                          //fontFamily: "Montserrat",
                                            fontSize: 16,
                                            color: Colors.black
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(bottom: 0),
                                      child: Text(
                                        listScores != null ? listScores.length > 0 ? listScores.length.toString() : "0" : "0",
                                        style: TextStyle(
                                          //fontFamily: "Montserrat",
                                            fontSize: 20,
                                            color: Colors.blue
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            child: Container(
                              margin: EdgeInsets.only(left: 0, top: 3),
                              //margin: EdgeInsets.only(top: 10),
                              child: Container(
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(top: 10, bottom: 5),
                                      child: Text(
                                        "Best score",
                                        style: TextStyle(
                                          //fontFamily: "Montserrat",
                                            fontSize: 16,
                                            color: Colors.black
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(bottom: 0),
                                      child: Text(
                                        listScores != null ? listScores.length > 0 ? listScores.reduce(max).toString().substring(0, listScores.reduce(max).toString().length - 2) : "0" : "0",
                                        style: TextStyle(
                                          //fontFamily: "Montserrat",
                                            fontSize: 20,
                                            color: Colors.green
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            child: Container(
                              margin: EdgeInsets.only(left: 0, top: 3),
                              //margin: EdgeInsets.only(top: 10),
                              child: Container(
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(top: 10, bottom: 5),
                                      child: Text(
                                        "Worst score",
                                        style: TextStyle(
                                          //fontFamily: "Montserrat",
                                            fontSize: 16,
                                            color: Colors.black
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(bottom: 0),
                                      child: Text(
                                        listScores != null ? listScores.length > 0 ? listScores.reduce(min).toString().substring(0, listScores.reduce(min).toString().length - 2) : "0" : "0",
                                        style: TextStyle(
                                          //fontFamily: "Montserrat",
                                            fontSize: 20,
                                            color: Colors.red
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      thickness: 7,
                      color: Colors.grey[300],
                    ),
                    Container(
                        margin: EdgeInsets.only(bottom: 20, top: 10),
                        child: Column(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(top: 5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(right: 5),
                                    child: Icon(Icons.play_circle_outline, color: Colors.blue[700]),
                                  ),
                                  Text("Actions", style: TextStyle(fontSize: 16, color: Colors.blue[700], fontWeight: FontWeight.w500),),
                                ],
                              )
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 5, bottom: 10),
                              child: Text("Start a new test or practice listening", style: TextStyle(fontSize: 12),),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Container(
                                  child: Container(
                                    height: 60,
                                    child: RaisedButton.icon(
                                      //elevation: 5.0,
                                      onPressed: () async {
                                        await Navigator.push(context, MaterialPageRoute(builder: (context) => DoTestScreen()));
                                        LocalFile.readContent().then((String value) {
                                          setState(() {
                                            data = value;
                                            readHistory();
                                          });
                                        });
                                      },
                                      icon: Container(
                                        margin: EdgeInsets.only(left: 0),
                                        child: Icon(Icons.ondemand_video, size: 30, color: Colors.white,),
                                      ),
                                      label: Container(
                                          margin: EdgeInsets.only(left: 0),
                                          width: MediaQuery.of(context).size.width/4,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  Translations.of(context).text('main_activity_button_start'),
                                                  style: TextStyle(
                                                    //fontFamily: 'Montserrat',
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(Translations.of(context).text('main_do_test'), style: TextStyle(color: Colors.white70, fontSize: 12),)
                                              ),
                                            ],
                                          )
                                      ),
                                      color: Colors.green,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black45,
                                          blurRadius: 2,
                                          spreadRadius: 0,
                                          offset: Offset(
                                              2,
                                              2
                                          )
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  child: Column(
                                    children: <Widget>[
                                      Container(
                                        child: Container(
                                          height: 60,
                                          child: RaisedButton.icon(
                                            //elevation: 5.0,
                                            onPressed: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => practiceList()));
                                            },
                                            color: Colors.blue,
                                            icon: Container(
                                              margin: EdgeInsets.only(left: 0),
                                              child: Icon(Icons.assignment_turned_in, size: 30, color: Colors.white,),
                                            ),
                                            label: Container(
                                                margin: EdgeInsets.only(left: 0),
                                                width: MediaQuery.of(context).size.width/4,
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Text(
                                                        Translations.of(context).text('main_activity_button_practice'),
                                                        style: TextStyle(
                                                          //fontFamily: 'Montserrat',
                                                          fontSize: 16,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Text(Translations.of(context).text('main_do_practice'), style: TextStyle(color: Colors.white70, fontSize: 12),),
                                                    )
                                                  ],
                                                )
                                            ),
                                          ),
                                        ),
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black45,
                                                blurRadius: 2,
                                                spreadRadius: 0,
                                                offset: Offset(
                                                    2,
                                                    2
                                                )
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        )
                    ),
                    Divider(
                      thickness: 7,
                      color: Colors.grey[300],
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 0, bottom: 30),
                      child: FutureBuilder(
                        future: readHistory(),
                        builder: (context, snapshot){
                          if(snapshot.connectionState == ConnectionState.done){
                            return Container(
                              margin: EdgeInsets.only(top: 20),
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.cyan[100], Colors.lightBlue[200]]
                                  )
                              ),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(top: 15),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Container(
                                          margin: EdgeInsets.only(right: 5),
                                          child: Icon(Icons.history, color: Colors.blue[700]),
                                        ),
                                        Text("History", style: TextStyle(fontSize: 16, color: Colors.blue[700], fontWeight: FontWeight.w500),),
                                      ],
                                    )
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 5),
                                    child: Text("See your performance here", style: TextStyle(fontSize: 12),),
                                  ),
                                  Container(
                                    height: 100,
                                    margin: EdgeInsets.only(left: 30, right: 30, bottom: 20, top: 10),
                                    child: Padding(
                                      padding: EdgeInsets.all(15),
                                      child: new Sparkline(
                                        data: listScores,
                                        pointsMode: PointsMode.all,
                                        pointSize: 8.0,
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(Radius.circular(15)),
                                      border: Border.all(width: 2.0, color: Colors.cyan),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(left: 10, right: 10),
                                    height: 300,
                                    width: MediaQuery.of(context).size.width,
                                    child: ListView(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      children: <Widget>[
                                        Container(
                                          height: 300,
                                          width: MediaQuery.of(context).size.width/2,
                                          child: Column(
                                            children: <Widget>[
                                              Container(
                                                height: 200,
                                                child: charts.PieChart(
                                                  _seriesPieDataGood,
                                                  animate: true,
                                                  animationDuration: Duration(seconds: 1),
                                                  defaultRenderer: new charts.ArcRendererConfig(
                                                      arcWidth: 100,
                                                      arcRendererDecorators: [
                                                        new charts.ArcLabelDecorator(
                                                          labelPosition: charts.ArcLabelPosition.inside,
                                                        )
                                                      ]
                                                  ),
                                                ),
                                              ),
                                              Text("Good score", style: TextStyle(color: Colors.blue[700], fontSize: 16),),
                                              Text("(more than 5)", style: TextStyle(color: Colors.blue[700], fontSize: 16),)
                                            ],
                                          ),
                                        ),
                                        Container(
                                          height: 300,
                                          width: MediaQuery.of(context).size.width/2,
                                          child: Column(
                                            children: <Widget>[
                                              Container(
                                                height: 200,
                                                child: charts.PieChart(
                                                  _seriesPieDataBad,
                                                  animate: true,
                                                  animationDuration: Duration(seconds: 1),
                                                  defaultRenderer: new charts.ArcRendererConfig(
                                                      arcWidth: 100,
                                                      arcRendererDecorators: [
                                                        new charts.ArcLabelDecorator(
                                                          labelPosition: charts.ArcLabelPosition.inside,
                                                        )
                                                      ]
                                                  ),
                                                ),
                                              ),
                                              Text("Bad score", style: TextStyle(color: Colors.blue[700], fontSize: 16),),
                                              Text("(less than 5)", style: TextStyle(color: Colors.blue[700], fontSize: 16),)
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          else if (snapshot.hasError){
                            return Container(
                              margin: EdgeInsets.only(top: 20, bottom: 20),
                              child: CircularProgressIndicator(),
                            );
                          }
                          else return Container(
                              margin: EdgeInsets.only(top: 20, bottom: 20),
                              child: CircularProgressIndicator(),
                            );
                        },
                      ),
                    ),
                  ],
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  //borderRadius: BorderRadius.only(topLeft: Radius.elliptical(250, 30), topRight: Radius.elliptical(250, 30)),
                ),
              ),
            ],
          ),
          decoration: BoxDecoration(
            //color: Colors.grey[300]
          ),
          //color: Colors.blueGrey[100],
        ),
      ],
    );
  }

  _tutorialPage(){
    return;
  }

  _infoPage(){
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                  margin: EdgeInsets.only(left: 20, right: 20, top: 30),
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        width: MediaQuery.of(context).size.width/4,
                        child: Image.asset("images/logo_ta.png"),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 10),
                        child: Text(
                          Translations.of(context).text('info_claim'),
                          style: TextStyle(
                              fontSize: 14
                          ),
                        ),
                      ),
                    ],
                  )
              ),
              Container(
                  margin: EdgeInsets.only(top: 20),
                  child: Divider(
                    color: Colors.grey[200],
                    thickness: 5,
                  )
              )
            ],
          ),
          Container(
            margin: EdgeInsets.only(left: 20, right: 20, top: 20),
            child: Column(
              children: <Widget>[
                Text(
                  "For more relative information or want to send any feedback, please contact us via:",
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Container(
                        width: MediaQuery.of(context).size.width/2 - 25,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Column(
                            children: <Widget>[
                              Icon(Icons.mail, size: 50, color: Colors.blue,),
                              Text("Abc@gmail.com", style: TextStyle(fontSize: 14),)
                            ],
                          ),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                              Radius.circular(10.0)
                          ),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 2,
                                spreadRadius: 0,
                                offset: Offset(
                                    2,
                                    2
                                )
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width/2 - 25,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Column(
                            children: <Widget>[
                              Icon(Icons.phone, size: 50, color: Colors.blue,),
                              Text("+84 123456789", style: TextStyle(fontSize: 14),)
                            ],
                          ),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                              Radius.circular(10.0)
                          ),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 2,
                                spreadRadius: 0,
                                offset: Offset(
                                    2,
                                    2
                                )
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                )
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 20, left: 20, right: 20),
            child: RichText(
              text: TextSpan(
                  children: [
                    WidgetSpan(
                        child: Container(
                          margin: EdgeInsets.only(right: 5),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                        )
                    ),
                    TextSpan(
                      text: Translations.of(context).text('info_address'),
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 14
                      ),
                    )
                  ]
              ),
            ),
          )
        ],
      )
    );
  }

}

class DoTestScreen extends StatefulWidget{
  State createState() => _DoTest();
}

class _DoTest extends State<DoTestScreen>{
  AudioPlayer audioPlayer = AudioPlayer();
  AudioCache audioCache = AudioCache();
  AudioCache notiSound = AudioCache();
  Duration duration = Duration();
  Duration position = Duration();
  bool isPlaying = true, isDisposed = false, isDisable = false;
  AudioPlayerState playerState;
  IconData iconAudio = Icons.pause;
  List<dynamic> myData;
  List<int> numbRandom, numbTrue, numbFalse;
  int numbOfTrue = 0, numbOfFalse = 0, currentPlaying, trueCount = 0, falseCount = 0;
  List<questionsModel> questionsList;
  double sceneOpacity = 1.0;
  Color buttonColor = Colors.red;
  List<resultModel> listResult = new List<resultModel>();

  @override
  void initState() {
    super.initState();
    questionsList = new List<questionsModel>();
    currentPlaying = 0;
    initPlayer();
    loadQuestionTrue();
    loadQuestionFalse();

    numbRandom = new List<int>.generate(9, (int index) => index);
    numbRandom.shuffle();
    numbOfTrue = numbRandom.elementAt(0) + 1;
    numbOfFalse = 10 - numbOfTrue;
    print("True: " + numbOfTrue.toString() + " & False: " + numbOfFalse.toString());
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
    numbTrue = new List<int>.generate(myData.length, (int index) => index);
    numbTrue.shuffle();
    print("myData: " + numbTrue.sublist(0).toString());
    for(int i = 0; i < numbOfTrue; i++){ //replace 5 by numbOfTrue when use
      questionsModel tempQuestion = new questionsModel("true/" + myData[numbTrue.elementAt(i)]["question_name"].toString(), myData[numbTrue.elementAt(i)]["answer"].toString());
      questionsList.add(tempQuestion);
    }
    print("Now playing: " + myData[numbTrue.elementAt(0)]["question_name"].toString());
  }

  void loadQuestionFalse() async {
    String temp = await loadJsonFalse();
    myData = json.decode(temp);
    numbFalse = new List<int>.generate(myData.length, (int index) => index);
    numbFalse.shuffle();
    print("myData: " + numbFalse.sublist(0).toString());
    for(int i = 0; i < numbOfFalse; i++){ //replace 5 by numbOfTrue when use
      questionsModel tempQuestion = new questionsModel("false/" + myData[numbFalse.elementAt(i)]["question_name"].toString(), myData[numbFalse.elementAt(i)]["answer"].toString());
      questionsList.add(tempQuestion);
    }
    showQuestions();
  }

  void showQuestions(){
    questionsList.shuffle();
    for(int i = 0; i < questionsList.length; i++){
      print("Question number " + i.toString() + ": " + questionsList.elementAt(i).getFilePath() + ", answer: " + questionsList.elementAt(i).getAnswer());
    }
    playAudio(questionsList.elementAt(currentPlaying).getFilePath());

  }

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
            buttonColor = Colors.green;
            isPlaying = false;
          }
          else if (msg == AudioPlayerState.PLAYING){
            playerState = msg;
            iconAudio = Icons.pause;
            buttonColor = Colors.redAccent;
            isPlaying = true;
          }
        });
      }
    });
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

  playLocal(String localPath) async {
    await audioCache.play(localPath);
  }

  void seekToSecond(int second){
    Duration newDuration = Duration(seconds: second);
    audioPlayer.seek(newDuration);
  }

  Widget titleQuestion(){
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                Translations.of(context).text('do_test_question'),
                style: TextStyle(
                  //fontFamily: "Monserrat",
                  fontSize: 16,
                  color: Colors.grey
                ),
              ),
              Text(
                (currentPlaying + 1).toString(),
                style: TextStyle(
                  //fontFamily: "Monserrat",
                  fontSize: 16,
                  color: Colors.grey
                ),
              ),
              Text(
                "/10",
                style: TextStyle(
                  //fontFamily: "Monserrat",
                  fontSize: 16,
                  color: Colors.grey
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 10),
            child: Text(
              Translations.of(context).text('do_test_title'),
              style: TextStyle(
                //fontFamily: "Monserrat",
                fontSize: 18,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget audioPlayerWidget(){
    return Container(
      margin: EdgeInsets.only(right: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            child: IconButton(
              onPressed: (){
                setState(() {
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
                });
              },
              icon: Icon(iconAudio, size: 30,),
              color: buttonColor,
            ),
          ),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(-5, 0, 0),
              child: Slider(
                activeColor: Colors.blue,
                inactiveColor: Colors.black,
                value: position.inSeconds.toDouble(),
                min: 0.0,
                max: duration.inSeconds.toDouble(),
                onChanged: (double value){
                  setState(() {
                    seekToSecond(value.toInt());
                    value = value;
                    resumeAudio();
                    iconAudio = Icons.pause;
                  });
                },
              ),
            )
          ),
          Container(
              margin: EdgeInsets.only(right: 10),
              child: Row(
                children: <Widget>[
                  Text(
                    position.inMinutes.toInt().toString(),
                    style: TextStyle(
                        fontSize: 16
                    ),
                  ),
                  Text(
                    ":",
                    style: TextStyle(
                        fontSize: 16
                    ),
                  ),
                  Text(
                    position.inSeconds.toInt().toString().length == 1 ? "0" + position.inSeconds.toInt().toString() : position.inSeconds.toInt().toString(),
                    style: TextStyle(
                        fontSize: 16
                    ),
                  ),
                  Text(
                    " / ",
                    style: TextStyle(
                        fontSize: 16
                    ),
                  ),
                  Text(
                    duration.inMinutes.toInt().toString(),
                    style: TextStyle(
                        fontSize: 16
                    ),
                  ),
                  Text(
                    ":",
                    style: TextStyle(
                        fontSize: 16
                    ),
                  ),
                  Text(
                    duration.inSeconds.toInt().toString().length == 1 ? "0" + duration.inSeconds.toInt().toString() : duration.inSeconds.toInt().toString(),
                    style: TextStyle(
                        fontSize: 16
                    ),
                  ),
                ],
              )
          ),

        ],
      ),
    );
  }

  Widget answerButtons(){
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(left: 30, right: 30, bottom: 10),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: IconButton(
              onPressed: (){
                if(isDisable == false){
                  if(questionsList.elementAt(currentPlaying).getAnswer() == "false"){
                    isDisable = true;
                    print("Good");
                    resultModel temp = new resultModel(questionsList.elementAt(currentPlaying).filePath, "true");
                    listResult.add(temp);
                    setState(() {
                      sceneOpacity = 0.0;
                    });
                    showTrueDialog(context);
                    audioPlayer.pause();
                    notiSound.play("true.mp3", volume: 0.5);
                    trueCount++;
                    Future.delayed(const Duration(milliseconds: 1500), (){
                      setState(() {
                        popDialog(context);
                        if(currentPlaying + 1 < 10){
                          Future.delayed(const Duration(milliseconds: 500), (){
                            setState(() {
                              isDisable = false;
                              sceneOpacity = 1.0;
                              currentPlaying++;
                              playAudio(questionsList.elementAt(currentPlaying).getFilePath());
                            });
                          });
                        }
                        else{
                          writeScore(trueCount, falseCount);
                          writeHistory(trueCount);
                          showResultDialog(context, trueCount, trueCount + falseCount, listResult);
                        }
                      });
                    });
                  }
                  else{
                    isDisable = true;
                    print("Bad");
                    resultModel temp = new resultModel(questionsList.elementAt(currentPlaying).filePath, "false");
                    listResult.add(temp);
                    setState(() {
                      sceneOpacity = 0.0;
                    });
                    showFalseDialog(context);
                    audioPlayer.pause();
                    notiSound.play("false.mp3", volume: 0.5);
                    falseCount++;
                    Future.delayed(const Duration(milliseconds: 1500), (){
                      setState(() {
                        popDialog(context);
                        if(currentPlaying + 1 < 10){
                          Future.delayed(const Duration(milliseconds: 500), (){
                            setState(() {
                              isDisable = false;
                              sceneOpacity = 1.0;
                              currentPlaying++;
                              playAudio(questionsList.elementAt(currentPlaying).getFilePath());
                            });
                          });
                        }
                        else{
                          writeScore(trueCount, falseCount);
                          writeHistory(trueCount);
                          showResultDialog(context, trueCount, trueCount + falseCount, listResult);
                        }
                      });
                    });
                  }
                }
                else{

                }
              },
              icon: Icon(Icons.close, color: Colors.white, size: 30,),
            ),
          ),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.all(
                Radius.circular(3.0)
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black45,
                  blurRadius: 1,
                  spreadRadius: 0,
                  offset: Offset(
                      2,
                      2
                  )
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 30, right: 30, top: 10),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: IconButton(
              onPressed: (){
                if(isDisable == false){
                  if(questionsList.elementAt(currentPlaying).getAnswer() == "true"){
                    isDisable = true;
                    print("Good");
                    resultModel temp = new resultModel(questionsList.elementAt(currentPlaying).filePath, "true");
                    listResult.add(temp);
                    setState(() {
                      sceneOpacity = 0.0;
                    });
                    showTrueDialog(context);
                    audioPlayer.pause();
                    notiSound.play("true.mp3", volume: 0.5);
                    trueCount++;
                    Future.delayed(const Duration(milliseconds: 1500), (){
                      setState(() {
                        popDialog(context);
                        if(currentPlaying + 1 < 10){
                          Future.delayed(const Duration(milliseconds: 500), (){
                            setState(() {
                              isDisable = false;
                              sceneOpacity = 1.0;
                              currentPlaying++;
                              playAudio(questionsList.elementAt(currentPlaying).getFilePath());
                            });
                          });
                        }
                        else{
                          writeScore(trueCount, falseCount);
                          writeHistory(trueCount);
                          showResultDialog(context, trueCount, trueCount + falseCount, listResult);
                        }
                      });
                    });
                  }
                  else{
                    isDisable = true;
                    print("Bad");
                    resultModel temp = new resultModel(questionsList.elementAt(currentPlaying).filePath, "false");
                    listResult.add(temp);
                    setState(() {
                      sceneOpacity = 0.0;
                    });
                    showFalseDialog(context);
                    audioPlayer.pause();
                    notiSound.play("false.mp3", volume: 1);
                    falseCount++;
                    Future.delayed(const Duration(milliseconds: 1500), (){
                      setState(() {
                        popDialog(context);
                        if(currentPlaying + 1 < 10){
                          Future.delayed(const Duration(milliseconds: 500), (){
                            setState(() {
                              isDisable = false;
                              sceneOpacity = 1.0;
                              currentPlaying++;
                              playAudio(questionsList.elementAt(currentPlaying).getFilePath());
                            });
                          });
                        }
                        else{
                          writeScore(trueCount, falseCount);
                          writeHistory(trueCount);
                          showResultDialog(context, trueCount, trueCount + falseCount, listResult);
                        }
                      });
                    });
                  }
                }
                else{

                }
              },
              icon: Icon(Icons.check, color: Colors.white, size: 30,),
            ),
          ),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.all(
                Radius.circular(3.0)
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black45,
                  blurRadius: 1,
                  spreadRadius: 0,
                  offset: Offset(
                      2,
                      2
                  )
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new MaterialApp(
      supportedLocales: [
        Locale('en'),
        Locale('vn'),
      ],
      home: new Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Opacity(
              opacity: sceneOpacity,
              child: Container(
                margin: EdgeInsets.only(top: MediaQuery.of(context).size.height/10),
                child: titleQuestion(),
              )
            ),
            Opacity(
              opacity: sceneOpacity,
              child: Container(
                margin: EdgeInsets.only(left: 30, right: 30),
                child: Container(
                  margin: EdgeInsets.only(top: 2),
                  child: audioPlayerWidget(),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    //border: Border.all(width: 2, color: Colors.grey),
                    borderRadius: BorderRadius.all(
                        Radius.circular(20.0)
                    ),

                  ),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.cyan, Colors.blue[700]]
                  ),
                  borderRadius: BorderRadius.all(
                      Radius.circular(20.0)
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        spreadRadius: 0,
                        offset: Offset(
                            2,
                            2
                        )
                    ),
                  ],
                ),
              )
            ),
            Opacity(
              opacity: sceneOpacity,
              child: Container(
                margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height/10),
                child: answerButtons(),
              )
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
    stopAudio();

  }
}

class Task{
  String task;
  double taskValue;
  Color taskColor;

  Task(this.task, this.taskValue, this.taskColor);
}