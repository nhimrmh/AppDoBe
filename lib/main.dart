import 'dart:async';
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
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:percent_indicator/percent_indicator.dart';
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
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'VideoPlayer.dart';
import 'ChooseLanguage.dart';
import 'ChooseCountry.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:flutter/scheduler.dart';
import 'package:connectivity/connectivity.dart';

String data;
String history;
String _mlanguage;
File jsonFile;
Directory dir;
String fileName = "history.json";
bool fileExists = false;
List<Map<String, dynamic>> fileContent;
bool hasPlayed = false;
List<double> listScores = [];
List<charts.Series<Task,String>> _seriesPieDataBad = new List<charts.Series<Task,String>>();
List<charts.Series<Task,String>> _seriesPieDataGood = new List<charts.Series<Task,String>>();
String isCountry;
var connectivityResult;

var badData = [
  new Task('Your Score', 33.5, Colors.red),
  new Task('All', 65.5, Colors.white)
];
var goodData = [
  new Task('Your Score', 33.5, Colors.red),
  new Task('All', 65.5, Colors.white)
];

Future checkConnection() async {
  connectivityResult = await (Connectivity().checkConnectivity());
  return;
}

_generateData_bad(){
  badData.clear();
  _seriesPieDataBad.clear();
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
          labelAccessorFn: (Task row,_) => '${row.taskValue}'.substring(0, '${row.taskValue}'.length -2) + "%"
      )
  );
}

_generateData_good(){
  goodData.clear();
  _seriesPieDataGood.clear();
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
          labelAccessorFn: (Task row,_) => '${row.taskValue}'.substring(0, '${row.taskValue}'.length -2) + "%"
      )
  );
}

void writeScore(int trueCount, int falseCount){
  LocalFile.readContent().then((String value) {
    data = value;
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
  });
}

Future readHistory() async {
  await getApplicationDocumentsDirectory().then((Directory directory) {
    dir = directory;
    jsonFile = new File(dir.path + "/" + fileName);
    fileExists = jsonFile.existsSync();
    if(fileExists) {
      listScores.clear();
      print("File exist");
      var temp = json.decode(jsonFile.readAsStringSync());
      if(temp.length > 1) {
        hasPlayed = true;
        print("Size > 1");
        for (int i = 0; i < temp.length; i++) {
          //print(temp.toString());
          listScores.add(double.parse(temp[i]["score"]));
        }
      }
      else if(temp.length == 1){
        hasPlayed = true;
        listScores.add(double.parse(temp["score"]));
      }
      else{
        hasPlayed = false;
        listScores.add(0);
      }
    }
    else{
      hasPlayed = false;
      listScores.clear();
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

void main() => runApp(_SplashScreenScene());

Future oneSecond() async {
  await Future.delayed(const Duration(milliseconds: 1000), (){
    return;
  });
}

Future delayPercent() async {
  await Future.delayed(const Duration(milliseconds: 2100), (){
    return;
  });
}

Future delaySplash() async {
  await Future.delayed(const Duration(milliseconds: 3000), (){
    return;
  });
}

Future delayShimmer() async {
  await Future.delayed(const Duration(milliseconds: 1600), (){
    return;
  });
}

class _SplashScreenScene extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _SplashScreen();
  }
}

class _SplashScreen extends State<_SplashScreenScene> with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation fadeInAnimation;
  Timer timer;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    fadeInAnimation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(controller);

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void moveToMain(BuildContext mContext) async{
    _mlanguage = await ChooseLanguage.readContent();
    //print("Current language is: " + _language);
    if(_mlanguage != null && _mlanguage.trim() != ""){
      WidgetsBinding.instance
          .addPostFrameCallback((_) => applic.onLocaleChanged(new Locale(_mlanguage,'')));
    }
    isCountry = await ChooseCountry.readContent();
    Navigator.pushReplacement(mContext, MaterialPageRoute(builder: (context) => MyApp()));
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      home: Builder(
        builder: (context){
          timer = new Timer(const Duration(milliseconds: 3500), (){
            moveToMain(context);
          });
          return Scaffold(
            body: FutureBuilder(
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
                              loop: 1,
                            )
                        )
                    ),
                  );
                }
              },
            ),
          );
        },
      )
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _PickLanguage createState() => new _PickLanguage();
}

class _PickLanguage extends State<MyApp> {
  SpecificLocalizationDelegate _localeOverrideDelegate;
  double vnOpacity = (_mlanguage == "en" || _mlanguage == null || _mlanguage.trim() == "" ? 0.0 : 1.0), enOpacity = (_mlanguage == "en" || _mlanguage == null || _mlanguage.trim() == "" ? 1.0 : 0.0);
  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    _localeOverrideDelegate = new SpecificLocalizationDelegate(null);
    applic.onLocaleChanged = onLocaleChange;
  }

  void moveToMain(BuildContext context){
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => DropDownScreen(context)
          )
      );
    });
  }

  onLocaleChange(Locale locale){
    setState((){
      _localeOverrideDelegate = new SpecificLocalizationDelegate(locale);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          builder: (context) {
            if(isCountry == "Success") moveToMain(context);
            return MediaQuery.removePadding(
              context: context,
              child: Scaffold(
                appBar: AppBar(backgroundColor: Colors.cyan, title: Text(Translations.of(context).text('pick_language_title')),),
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
                                      vnOpacity = 1.0;
                                      enOpacity = 0.0;
                                      _mlanguage = "vn";
                                      applic.onLocaleChanged(new Locale('vn',''));
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 25.0, left: 10.0, right: 10.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Container(
                                            transform: Matrix4.translationValues(20, 0, 0),
                                            width: 60,
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 15.0),
                                              child: Image.asset('vn.png'),
                                            ),
                                          ),
                                          Container(
                                            transform: Matrix4.translationValues(20, 0, 0),
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
                                          Opacity(
                                            opacity: vnOpacity,
                                            child: Icon(Icons.check, color: Colors.green, size: 30,),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  new GestureDetector(
                                    onTap: (){
                                      vnOpacity = 0.0;
                                      enOpacity = 1.0;
                                      _mlanguage = "en";
                                      applic.onLocaleChanged(new Locale('en',''));
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 20.0, left: 10.0, right: 10.0, bottom: 25.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Container(
                                            transform: Matrix4.translationValues(20, 0, 0),
                                            width: 60,
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 15.0),
                                              child: Image.asset('us.png'),
                                            ),
                                          ),
                                          Container(
                                            transform: Matrix4.translationValues(20, 0, 0),
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
                                          Opacity(
                                            opacity: enOpacity,
                                            child: Icon(Icons.check, color: Colors.green, size: 30,),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                                    width: double.infinity,
                                    child: RaisedButton.icon(
                                      onPressed: (){
                                        if(_mlanguage == null || _mlanguage.trim() == "") _mlanguage = "en";
                                        ChooseLanguage.writeContent(_mlanguage);
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => _PickCountryScene()));
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
                ),
              ),
              removeTop: true,
            );
          }
      ),
    );
  }
}

class _PickCountryScene extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _PickCountry();
  }
}

class _PickCountry extends State<_PickCountryScene> {

  static String countryName = "Error", countryCode = "+84";
  List<dynamic> itemsList = List();
  var envelope;
  double reloadOpacity = 0.0, mainOpacity = 1.0;

  Future sendCountry() async {
    http.Response response =
    await http.post('http://dobe.capnuoctrungan.vn/DoBeWebService.asmx',
        headers: {
          "Content-Type": "text/xml; charset=utf-8",
          "SOAPAction": "http://tempuri.org/SendCountry",
          "Host": "dobe.capnuoctrungan.vn"
        },
        body: envelope);
    var _response = response.body;
    await _parsing(_response);
  }

  Future _parsing(var _response) async {
    var _document = xml.parse(_response);
    Iterable<xml.XmlElement> items = _document.findAllElements('SendCountryResponse');
    items.map((xml.XmlElement item) {
      var _addResult = _getValue(item.findElements("SendCountryResult"));
      itemsList.add(_addResult);
    }).toList();

    print("itemsList: " + itemsList.elementAt(0).toString());
    if(itemsList.elementAt(0).toString() == "Success") ChooseCountry.writeContent("Success");
    else ChooseCountry.writeContent("Fail");
  }

  _getValue(Iterable<xml.XmlElement>  items) {
    var textValue;
    items.map((xml.XmlElement node) {
      textValue = node.text;
    }).toList();
    return textValue;
  }

  void getInfo(){
     countryName = getName();
     countryCode = getCode();
     print(countryName);
     print(countryCode);
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      child: Scaffold(
          appBar: AppBar(backgroundColor: Colors.cyan, title: Text(Translations.of(context).text('pick_country_title')),),
          body: FutureBuilder(
            future: checkConnection(),
            builder: (context, snapshot){
              if(snapshot.connectionState == ConnectionState.done){
                if(connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi){
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
                                      child: Container(
                                        height: 60,
                                        child: Container(
                                          margin: EdgeInsets.only(left: 20, right: 20),
                                          child: CountryCodePicker(
                                            onChanged: print,
                                            initialSelection: 'VN',
                                            showCountryOnly: false,
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
                                          getInfo();
                                          envelope = "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><SendCountry xmlns=\"http://tempuri.org/\"><countryName>" + countryName + "</countryName><countryCode>" + countryCode + "</countryCode></SendCountry></soap:Body></soap:Envelope>";
                                          sendCountry();
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => DropDownScreen(context)));
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
                  );
                }
                else return Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Stack(
                      children: <Widget>[
                        Opacity(
                          opacity: reloadOpacity,
                          child: Center(
                            child: Container(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(),
                            ),
                          )
                        ),
                        Opacity(
                          opacity: mainOpacity,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.all(20),
                                  child: Text("Please enable network to continue", style: TextStyle(fontSize: 20),),
                                ),
                                RaisedButton.icon(
                                    onPressed: (){
                                      setState(() {
                                        mainOpacity = 0.0;
                                        reloadOpacity = 1.0;
                                        Future.delayed(const Duration(milliseconds: 1000), (){
                                          setState(() {
                                            mainOpacity = 1.0;
                                            reloadOpacity = 0.0;
                                          });
                                        });
                                      });
                                    },
                                    icon: Icon(Icons.refresh),
                                    label: Text("Reload")
                                )
                              ],
                            ),
                          )
                        )
                      ],
                    )
                  )
                );
              }
              else{
                return Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          )
      ),
      removeTop: true,
    );
  }
}

class DropDownScreen extends StatefulWidget{
  BuildContext context;
  DropDownScreen(this.context);
  @override
  State createState() => _MainScreen(context);

}

class _MainScreen extends State<DropDownScreen> with SingleTickerProviderStateMixin{
  BuildContext _mContext, _backContext;
  static int index = 0;
  String app_bar_main = "app_bar_main";
  static const String vn = 'Tiếng Việt';
  static const String en = 'English';
  AnimationController controller;
  Animation<Offset> offset, offset1, offset2;
  _MainScreen(this._backContext);

  static const List<String> choices = <String>[
    vn,
    en
  ];

  Future getData() async {
    await readHistory();
    _generateData_bad();
    _generateData_good();
  }

  Future<bool> _onBackPressed (){
    return showDialog(
      context: _backContext,
      builder: (context) => new AlertDialog(
        title: new Text(Translations.of(_backContext).text("dialog_exit")),
        actions: <Widget>[
          new RaisedButton.icon(
            icon: Icon(Icons.close, color: Colors.white,),
            label: Text(Translations.of(_backContext).text("dialog_no"), style: TextStyle(color: Colors.white),),
            onPressed: () => Navigator.of(context).pop(false),
            elevation: 0.0,
            color: Colors.redAccent,
          ),
          new RaisedButton.icon(
            icon: Icon(Icons.exit_to_app, color: Colors.white,),
            label: Text(Translations.of(_backContext).text("dialog_yes"), style: TextStyle(color: Colors.white),),
            onPressed: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
            elevation: 0.0,
            color: Colors.green,
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<bool> _showConfirmDialog (){
    return showDialog(
      context: _backContext,
      builder: (context) => new AlertDialog(
        title: new Row(
          children: <Widget>[
            Icon(Icons.warning, color: Colors.redAccent, size: 30,),
            Container(
              margin: EdgeInsets.only(left: 10),
              child: Text(Translations.of(_backContext).text("dialog_warning"))
            )
          ],
        ),
        content: new Text(Translations.of(_backContext).text("dialog_warning_detail")),
        actions: <Widget>[
          new RaisedButton.icon(
            icon: Icon(Icons.close, color: Colors.white,),
            label: Text(Translations.of(_backContext).text("dialog_cancel"), style: TextStyle(color: Colors.white),),
            onPressed: () => Navigator.of(context).pop(false),
            elevation: 0.0,
            color: Colors.redAccent,
          ),
          new RaisedButton.icon(
            icon: Icon(Icons.forward, color: Colors.white,),
            label: Text(Translations.of(_backContext).text("dialog_start"), style: TextStyle(color: Colors.white),),
            onPressed: () async {
              Navigator.of(context).pop(false);
              await Navigator.push(_backContext, MaterialPageRoute(builder: (context) => ReadyScreen())); //fix this, read before dotestscreen done
              LocalFile.readContent().then((String value) {
                setState(() {
                  data = value;
                  getData();
                });
              });
            },
            elevation: 0.0,
            color: Colors.green,
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    print("Language in main: " + _mlanguage);

    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    offset = Tween<Offset>(begin: Offset(0.0, 1.5), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: controller,
        curve: Curves.bounceOut
    ));

    offset1 = Tween<Offset>(begin: Offset(0.0, 1.5), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: controller,
        curve: Curves.bounceOut
    ));

    offset2 = Tween<Offset>(begin: Offset(0.0, 1.5), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: controller,
        curve: Curves.bounceOut
    ));

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
    //_mContext = context;
    return new WillPopScope(
        child: MaterialApp(
            supportedLocales: [
              Locale('en'),
              Locale('vn'),
            ],
            home: GestureDetector(
              child: Stack(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.cyan,
                            Colors.blue[900]
                          ],
                        )
                    ),
                  ),
                  Scaffold(
                      backgroundColor: Colors.transparent,
                      bottomNavigationBar: BottomNavigationBar(
                        backgroundColor: Colors.black,
                        selectedItemColor: Colors.white,
                        unselectedItemColor: Colors.white70,
                        showSelectedLabels: false,
                        selectedIconTheme: IconThemeData(size: 30),
                        selectedLabelStyle: TextStyle(height: 0),
                        unselectedLabelStyle: TextStyle(height: 1),
                        //backgroundColor: Colors.blue,
                        currentIndex: index,
                        onTap: (value) => setState(() {
                          index = value;
                          app_bar_main = (index == 0 ? "app_bar_main" : index == 1 ? "app_bar_tutorial" : "app_bar_info");
                        }),
                        items: [
                          BottomNavigationBarItem(
                              icon: new Icon(Icons.home),
                              title: new Text(Translations.of(_backContext).text('main_activity_home'))
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
                            new MediaQuery.removePadding(
                              context: context,
                              child: SliverAppBar(
                                backgroundColor: innerBoxIsScrolled == true ? Colors.cyan : Colors.transparent,
                                leading: Container(
                                  transform: Matrix4.translationValues(8, 0, 0),
                                  child: Image.asset("images/logo-3d-metal_small.png", scale: 3,),
                                ),
                                actions: <Widget>[
                                  IconButton(
                                    icon: Icon(
                                      Icons.play_circle_outline,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      _showConfirmDialog();
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.folder_open,
                                      color: Colors.white,
                                    ),
                                    onPressed: () async {
                                      Navigator.push(_backContext, MaterialPageRoute(builder: (context) => practiceList(_backContext)));
                                    },
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (String choice){
                                      if(choice == "English") {
                                        ChooseLanguage.writeContent("en");
                                        applic.onLocaleChanged(new Locale('en',''));
                                      }
                                      else {
                                        ChooseLanguage.writeContent("vn");
                                        applic.onLocaleChanged(new Locale('vn',''));
                                      }
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
                                pinned: false,
                                snap: true,
                                floating: true,
                                forceElevated: innerBoxIsScrolled,
                                elevation: 0,
                              ),
                              removeTop: true,
                            )
                          ];
                        },
                        body: _getBody(index),
                      )
                  ),
                ],
              ),
              onTapDown: (e){
                SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
              },
              onVerticalDragDown: (e){
                SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
              },
              onHorizontalDragDown: (e){
                SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
              },
            )
        ),
        onWillPop: _onBackPressed
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
    controller.reset();
    controller.forward();
    return MediaQuery.removePadding(
      context: context,
      child: ListView(
        children: <Widget>[
          Container(
              width: double.infinity,
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    child: CircularPercentIndicator(
                      radius: 80.0,
                      lineWidth: 10.0,
                      animation: true,
                      percent: data == null ? 0 : ((data.indexOf("*") != -1 && data.indexOf("%") != -1) ? (data.substring(0, data.indexOf("%")).length > 4 ? double.parse((data.substring(0, 3) + (int.parse(data.substring(4, 5)) >= 5 ? ((int.parse(data.substring(3, 4)) + 1).toString().length == 1 ? (int.parse(data.substring(3, 4)) + 1).toString() : (int.parse(data.substring(3, 4)) + 1).toString().substring(0,1)) : data.substring(3, 4))))/10.0 : double.parse(data.substring(0, data.indexOf("%")))/10.0) : 0),
                      center: new FutureBuilder(
                          future: delayPercent(),
                          builder: (context, snapshot) {
                            if(snapshot.connectionState == ConnectionState.done) return Text(
                              data == null ? "0" : ((data.indexOf("*") != -1 && data.indexOf("%") != -1) ? (data.substring(0, data.indexOf("%")).length > 4 ? (data.substring(0, 3) + (int.parse(data.substring(4, 5)) >= 5 ? ((int.parse(data.substring(3, 4)) + 1).toString().length == 1 ? (int.parse(data.substring(3, 4)) + 1).toString() : (int.parse(data.substring(3, 4)) + 1).toString().substring(0,1)) : data.substring(3, 4))) : data.substring(0, data.indexOf("%"))) : "0"),
                              style:
                              new TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.w500),
                            );
                            else return Text("...", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),);
                          }
                      ),
                      circularStrokeCap: CircularStrokeCap.square,
                      animationDuration: 2000,
                      progressColor: data == null ? Colors.redAccent : (data.indexOf("*") != -1 && data.indexOf("%") != -1) ? double.parse(data.substring(0, data.indexOf("%"))) > 5 ? Colors.lightGreen : Colors.redAccent : Colors.redAccent,
                    ),
                  ),
                  SlideTransition(
                    position: offset,
                    child: Container(
                      margin: EdgeInsets.only(left: 20),
                      child: Image.asset("images/man_large.png", scale: 2,),
                    ),
                  )
                ],
              )
          ),
          Container(
            child: Column(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.all(10),
                  child: Column(
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(right: 5),
                              child: Icon(Icons.av_timer, color: Colors.blue[700]),
                            ),
                            Text(Translations.of(context).text('main_activity_overview'), style: TextStyle(fontSize: 16, color: Colors.blue[700], fontWeight: FontWeight.w500),),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 5, bottom: 5),
                        child: Text(Translations.of(context).text('main_activity_overview_detail'), style: TextStyle(fontSize: 12),),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 30, right: 30),
                        child: Divider(
                            thickness: 1.0,
                            color: Colors.blueGrey[100]
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 5, bottom: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              child: Container(
                                margin: EdgeInsets.only(left: 0, top: 3),
                                width: MediaQuery.of(context).size.width/2.75,
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
                                              fontSize: 14,
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
                                              fontSize: 30,
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
                                width: MediaQuery.of(context).size.width/2.75,
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
                                              fontSize: 14,
                                              color: Colors.black
                                          ),
                                        ),
                                      ),
                                      Container(
                                          margin: EdgeInsets.only(bottom: 0),
                                          child: FutureBuilder(
                                            future: delayPercent(),
                                            builder: (context, snapshot){
                                              if(snapshot.connectionState == ConnectionState.done){
                                                return Text(
                                                  data == null ? "0" : ((data.indexOf("*") != -1 && data.indexOf("%") != -1) ? (data.substring(0, data.indexOf("%")).length > 4 ? (data.substring(0, 3) + (int.parse(data.substring(4, 5)) >= 5 ? ((int.parse(data.substring(3, 4)) + 1).toString().length == 1 ? (int.parse(data.substring(3, 4)) + 1).toString() : (int.parse(data.substring(3, 4)) + 1).toString().substring(0,1)) : data.substring(3, 4))) : data.substring(0, data.indexOf("%"))) : "0"),
                                                  style: TextStyle(
                                                    //fontFamily: "Montserrat",
                                                      fontSize: 30,
                                                      color: Colors.blue
                                                  ),
                                                );
                                              }
                                              else return Container(
                                                transform: Matrix4.translationValues(0, 5, 0),
                                                child: CircularProgressIndicator(),
                                              );
                                            },
                                          )
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
                        margin: EdgeInsets.only(top: 0, bottom: 5),
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
                                          Translations.of(context).text('main_activity_times'),
                                          style: TextStyle(
                                            //fontFamily: "Montserrat",
                                              fontSize: 14,
                                              color: Colors.black
                                          ),
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(bottom: 0),
                                        child: Text(
                                          listScores != null ? listScores.length > 0 ? hasPlayed == true ? listScores.length.toString() : "0" : "0" : "0",
                                          style: TextStyle(
                                            //fontFamily: "Montserrat",
                                              fontSize: 16,
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
                                          Translations.of(context).text('main_activity_best'),
                                          style: TextStyle(
                                            //fontFamily: "Montserrat",
                                              fontSize: 14,
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
                                              fontSize: 16,
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
                                          Translations.of(context).text('main_activity_worst'),
                                          style: TextStyle(
                                            //fontFamily: "Montserrat",
                                              fontSize: 14,
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
                                              fontSize: 16,
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
                    ],
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                ),
                Container(
                  child: Divider(
                      thickness: 8.0,
                      color: Colors.blueGrey[50]
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(10),
                  child: Column(
                    children: <Widget>[
                      Container(
                          margin: EdgeInsets.only(top: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(right: 5),
                                child: Icon(Icons.play_circle_outline, color: Colors.blue[700]),
                              ),
                              Text(Translations.of(context).text('main_activity_action'), style: TextStyle(fontSize: 16, color: Colors.blue[700], fontWeight: FontWeight.w500),),
                            ],
                          )
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 5, bottom: 5),
                        child: Text(Translations.of(context).text('main_activity_action_detail'), style: TextStyle(fontSize: 12),),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 30, right: 30),
                        child: Divider(
                            thickness: 1.0,
                            color: Colors.blueGrey[100]
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 5, top: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              child: Container(
                                child: RaisedButton.icon(
                                  //elevation: 5.0,
                                  onPressed: () async {
                                    _showConfirmDialog();
                                  },
                                  icon: Container(
                                    margin: EdgeInsets.only(left: 0),
                                    child: Icon(Icons.play_circle_outline, size: 30, color: Colors.white,),
                                  ),
                                  label: Container(
                                      margin: EdgeInsets.only(left: 0),
                                      width: MediaQuery.of(context).size.width/4,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                margin: EdgeInsets.only(top: 8),
                                                child: Text(
                                                  Translations.of(context).text('main_activity_button_start'),
                                                  style: TextStyle(
                                                    //fontFamily: 'Montserrat',
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              )
                                          ),
                                          Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                  margin: EdgeInsets.only(bottom: 8),
                                                  child: Text(Translations.of(context).text('main_do_test'), style: TextStyle(color: Colors.white70, fontSize: 12),)
                                              )
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
                                      child: RaisedButton.icon(
                                        //elevation: 5.0,
                                        onPressed: (){
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => practiceList(_backContext)));
                                        },
                                        color: Colors.blue,
                                        icon: Container(
                                          margin: EdgeInsets.only(left: 0),
                                          child: Icon(Icons.folder_open, size: 30, color: Colors.white,),
                                        ),
                                        label: Container(
                                            margin: EdgeInsets.only(left: 0),
                                            width: MediaQuery.of(context).size.width/4,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                                Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Container(
                                                      margin: EdgeInsets.only(top: 8),
                                                      child: Text(
                                                        Translations.of(context).text('main_activity_button_practice'),
                                                        style: TextStyle(
                                                          //fontFamily: 'Montserrat',
                                                          fontSize: 16,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    )
                                                ),
                                                Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Container(
                                                      margin: EdgeInsets.only(bottom: 8),
                                                      child: Text(Translations.of(context).text('main_do_practice'), style: TextStyle(color: Colors.white70, fontSize: 12),),
                                                    )
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
                      )
                    ],
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                ),
                Container(
                  child: Divider(
                      thickness: 8.0,
                      color: Colors.blueGrey[50]
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(10),
                  child: FutureBuilder(
                    future: readHistory(),
                    builder: (context, snapshot){
                      if(snapshot.connectionState == ConnectionState.done){
                        return Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.cyan,
                                  Colors.lightBlue[600]
                                ],
                              )
                          ),
                          child: Column(
                            children: <Widget>[
                              Container(
                                  margin: EdgeInsets.only(top: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        margin: EdgeInsets.only(right: 5),
                                        child: Icon(Icons.history, color: Colors.white),
                                      ),
                                      Text(Translations.of(_backContext).text('main_activity_history'), style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),),
                                    ],
                                  )
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 5, bottom: 5),
                                child: Text(Translations.of(_backContext).text('main_activity_history_detail'), style: TextStyle(fontSize: 12, color: Colors.white),),
                              ),
                              Container(
                                margin: EdgeInsets.only(left: 30, right: 30),
                                child: Divider(
                                    thickness: 1.0,
                                    color: Colors.white
                                ),
                              ),
                              Container(
                                height: 100,
                                margin: EdgeInsets.only(left: 30, right: 30, bottom: 0, top: 5),
                                child: Padding(
                                  padding: EdgeInsets.all(15),
                                  child: new Sparkline(
                                    data: listScores,
                                    pointsMode: PointsMode.last,
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
                                height: 190,
                                width: MediaQuery.of(context).size.width,
                                child: ListView(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  children: <Widget>[
                                    Container(
                                      height: 150,
                                      width: MediaQuery.of(context).size.width/2 - 20,
                                      child: Column(
                                        children: <Widget>[
                                          Container(
                                            height: 150,
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
                                          Container(
                                              transform: Matrix4.translationValues(0, -10, 0),
                                              child: Column(
                                                children: <Widget>[
                                                  Text(Translations.of(_backContext).text('main_activity_good'), style: TextStyle(color: Colors.white, fontSize: 14),),
                                                  Text(Translations.of(_backContext).text('main_activity_good_detail'), style: TextStyle(color: Colors.white, fontSize: 12),)
                                                ],
                                              )
                                          )
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: 150,
                                      width: MediaQuery.of(context).size.width/2 - 20,
                                      child: Column(
                                        children: <Widget>[
                                          Container(
                                            height: 150,
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
                                          Container(
                                              transform: Matrix4.translationValues(0, -10, 0),
                                              child: Column(
                                                children: <Widget>[
                                                  Text(Translations.of(_backContext).text('main_activity_bad'), style: TextStyle(color: Colors.white, fontSize: 14),),
                                                  Text(Translations.of(_backContext).text('main_activity_bad_detail'), style: TextStyle(color: Colors.white, fontSize: 12),)
                                                ],
                                              )
                                          )
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
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25)
              ),
            ),
          ),
        ],
      ),
      removeTop: true,
    );
  }

  _tutorialPage(){
    controller.reset();
    controller.forward();
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ListView(
          children: <Widget>[
            SlideTransition(
              position: offset1,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: EdgeInsets.only(left: 20, right: 10),
                  child: Image.asset("images/theory_large.png", scale: 3.0,),
                ),
              )
            ),
            Container(
              width: double.infinity,
              height: 25,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))
              ),
            ),
            Container(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 0),
                      child: Text(Translations.of(context).text('theory_header_1'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_content_1'),
                        style: TextStyle(fontSize: 14),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_title_1'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 10),
                      child: Image.asset("images/hinh_1.png", fit: BoxFit.cover,),
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_title_2'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 10),
                      child: Image.asset("images/hinh_2.png", fit: BoxFit.cover,),
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_title_3'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 10),
                      child: Image.asset("images/hinh_3.png", fit: BoxFit.cover,),
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_title_4'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 10),
                      child: Image.asset("images/hinh_4.png", fit: BoxFit.cover,),
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 40),
                      child: Text(Translations.of(context).text('theory_header_2'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_title_5'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_content_2'),
                        style: TextStyle(fontSize: 14),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_content_3'),
                        style: TextStyle(fontSize: 14),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_title_6'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_content_4'),
                        style: TextStyle(fontSize: 14),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: Translations.of(context).text('theory_content_5') != "" ? EdgeInsets.only(top: 20) : EdgeInsets.only(top: 0),
                      child: Translations.of(context).text('theory_content_5') != "" ? Text(
                        Translations.of(context).text('theory_content_5'),
                        style: TextStyle(fontSize: 14),
                      ) : null
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_content_6'),
                        style: TextStyle(fontSize: 14),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_content_7'),
                        style: TextStyle(fontSize: 14),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_content_8'),
                        style: TextStyle(fontSize: 14),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_content_9'),
                        style: TextStyle(fontSize: 14),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                        Translations.of(context).text('theory_content_10'),
                        style: TextStyle(fontSize: 14),
                      )
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 10),
                      child: Image.asset("images/hinh_5.png", fit: BoxFit.cover,),
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 10, bottom: 20),
                      child: Image.asset("images/hinh_6.png", fit: BoxFit.cover,),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      )
    );
  }

  _infoPage(){
    controller.reset();
    controller.forward();
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: MediaQuery.removePadding(
        context: context,
        child: ListView(
          children: <Widget>[
            SlideTransition(
                position: offset2,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Image.asset("images/contact.png", scale: 3.5,),
                )
            ),
            Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                        color: Colors.blueGrey[50],
                        thickness: 8,
                      )
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 20, right: 20, top: 20),
                    child: Text(
                      Translations.of(context).text('info_introduce'),
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    color: Colors.white,
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 20, right: 20, top: 20),
                    child: Text(
                      Translations.of(context).text('info_contact'),
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    color: Colors.white,
                  ),
                  Container(
                    margin: EdgeInsets.all(20),
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        children: <Widget>[
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 20, right: 0),
                                child: Icon(Icons.mail, size: 50, color: Colors.blue,),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 5, left: 20),
                                child: Text("Email", style: TextStyle(fontSize: 16),),
                              ),
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 20, right: 20),
                            width: 2,
                            height: 80,
                            color: Colors.blueGrey[200],
                          ),
                          Expanded(
                            child: Center(
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(bottom: 20),
                                    width: double.infinity,
                                    child: Text("- gndktcnta@gmail.com", style: TextStyle(fontSize: 14),),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(bottom: 5),
                                    width: double.infinity,
                                    child: Text(Translations.of(context).text('info_thong') + Translations.of(context).text('info_manager'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(bottom: 0),
                                    width: double.infinity,
                                    child: Text("- hominhthong1982@gmail.com", style: TextStyle(fontSize: 14),),
                                  ),
                                ],
                              ),
                            ),
                          )
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
                    margin: EdgeInsets.all(20),
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        children: <Widget>[
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 20, right: 0),
                                child: Icon(Icons.mail, size: 50, color: Colors.blue,),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 5, left: 20),
                                child: Text("Email", style: TextStyle(fontSize: 16),),
                              ),
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 20, right: 20),
                            width: 2,
                            height: 80,
                            color: Colors.blueGrey[200],
                          ),
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(bottom: 5),
                                  width: double.infinity,
                                  child: Text( Translations.of(context).text('info_trieu') + Translations.of(context).text('info_manager'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),),
                                ),
                                Container(
                                  margin: EdgeInsets.only(bottom: 20),
                                  width: double.infinity,
                                  child: Text("- trieu1929@yahoo.com", style: TextStyle(fontSize: 14),),
                                ),
                                Container(
                                  margin: EdgeInsets.only(bottom: 5),
                                  width: double.infinity,
                                  child: Text(Translations.of(context).text('info_nhan') + Translations.of(context).text('info_dev'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),),
                                ),
                                Container(
                                  margin: EdgeInsets.only(bottom: 0),
                                  width: double.infinity,
                                  child: Text("- nhimrmh@gmail.com", style: TextStyle(fontSize: 14),),
                                ),
                              ],
                            ),
                          )
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
                    margin: EdgeInsets.all(20),
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        children: <Widget>[
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 20, right: 0),
                                child: Icon(Icons.language, size: 50, color: Colors.blue,),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 5, left: 20),
                                child: Text("Website", style: TextStyle(fontSize: 16),),
                              ),
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 20, right: 20),
                            width: 2,
                            height: 80,
                            color: Colors.blueGrey[200],
                          ),
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                Container(
                                  width: double.infinity,
                                  child: Text("capnuoctrungan.vn", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.blue[700]),),
                                ),
                              ],
                            ),
                          )
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
                    margin: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 0),
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
                    color: Colors.white,
                  ),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 20),
                    child: RichText(
                      text: TextSpan(
                          children: [
                            TextSpan(
                              text: Translations.of(context).text('info_freepik'),
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14
                              ),
                            ),
                            TextSpan(
                              text: "Freepik",
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14
                              ),
                            ),
                            WidgetSpan(
                                child: Container(
                                  margin: EdgeInsets.only(left: 5),
                                  child: Image.asset("images/freepik.png", scale: 3,)
                                )
                            ),
                          ]
                      ),
                    ),
                    color: Colors.white,
                  ),
                ],
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
              ),
            ),
          ],
        ),
        removeTop: true,
      )
    );
  }

}

class ReadyScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return Ready();
  }
}

class Ready extends State<ReadyScreen> with SingleTickerProviderStateMixin {
  int count = 3;
  AnimationController controller;
  Animation<Offset> offset;
  Timer timer;

  void moveToMain(BuildContext mContext) async {
    await Navigator.push(mContext, MaterialPageRoute(builder: (context) => ReadyScreen1()));
    Navigator.pop(mContext);
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );

    offset = Tween<Offset>(begin: Offset(0.0, -3.0), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: controller,
        curve: Curves.bounceOut
    ));

    timer = new Timer(const Duration(seconds: 1), (){moveToMain(context);});
    controller.forward();
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Center(
          child: SlideTransition(
              position: offset,
              child: Container(
                height: 200,
                width: 200,
                child: Center(
                  child: Text(count.toString(), style: TextStyle(fontSize: 100, color: Colors.white),),
                ),
                decoration: BoxDecoration(
                    color: Colors.blueGrey[300],
                    shape: BoxShape.circle
                ),
              )
          )
        )
      ),
    );
  }
}

class ReadyScreen1 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return Ready1();
  }
}

class Ready1 extends State<ReadyScreen1> with SingleTickerProviderStateMixin {
  int count = 2;
  AnimationController controller;
  Animation<Offset> offset;
  Timer timer;

  void moveToMain(BuildContext mContext) async {
    await Navigator.push(mContext, MaterialPageRoute(builder: (context) => ReadyScreen2()));
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );

    offset = Tween<Offset>(begin: Offset(0.0, -3.0), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: controller,
        curve: Curves.bounceOut
    ));

    timer = new Timer(const Duration(seconds: 1), (){moveToMain(context);});
    controller.forward();
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Center(
            child: SlideTransition(
                position: offset,
                child: Container(
                  height: 200,
                  width: 200,
                  child: Center(
                    child: Text(count.toString(), style: TextStyle(fontSize: 100, color: Colors.white),),
                  ),
                  decoration: BoxDecoration(
                      color: Colors.blueGrey[300],
                      shape: BoxShape.circle
                  ),
                )
            ),
          )
      ),
    );
  }
}

class ReadyScreen2 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return Ready2();
  }
}

class Ready2 extends State<ReadyScreen2> with SingleTickerProviderStateMixin {
  int count = 1;
  AnimationController controller;
  Animation<Offset> offset;
  Timer timer;

  void moveToMain(BuildContext mContext) async {
    await Navigator.push(mContext, MaterialPageRoute(builder: (context) => DoTestScreen()));
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );

    offset = Tween<Offset>(begin: Offset(0.0, -3.0), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: controller,
        curve: Curves.bounceOut
    ));

    timer = new Timer(const Duration(seconds: 1), (){moveToMain(context);});
    controller.forward();
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Center(
            child: SlideTransition(
                position: offset,
                child: Container(
                  height: 200,
                  width: 200,
                  child: Center(
                    child: Text(count.toString(), style: TextStyle(fontSize: 100, color: Colors.white),),
                  ),
                  decoration: BoxDecoration(
                      color: Colors.blueGrey[300],
                      shape: BoxShape.circle
                  ),
                )
            )
          )
      ),
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
  List<int> numbRandom, numbRandom_standard, numbTrue, numbFalse, numbStandard;
  int numbOfTrue = 0, numbOfFalse = 0, numbOfStandard = 0, currentPlaying, trueCount = 0, falseCount = 0;
  List<questionsModel> questionsList;
  double sceneOpacity = 1.0;
  Color buttonColor = Colors.red;
  List<resultModel> listResult = new List<resultModel>();
  String question, no, yes;

  @override
  void initState() {
    super.initState();
    questionsList = new List<questionsModel>();
    currentPlaying = 0;
    initPlayer();
    loadQuestionTrue();
    loadQuestionFalse();
    loadQuestionStandard();
    numbRandom = new List<int>.generate(5, (int index) => index);
    numbRandom.shuffle();
    numbOfTrue = numbRandom.elementAt(0) + 3;
    numbRandom_standard = new List<int>.generate(numbOfTrue == 1 ? numbOfTrue + 1 : numbOfTrue, (int index) => index);
    numbRandom_standard.shuffle();
    numbOfStandard = numbRandom_standard.elementAt(0);
    numbOfFalse = 10 - numbOfTrue;
    print("True: " + numbOfTrue.toString() + " & False: " + numbOfFalse.toString());
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
    String temp = await loadJsonTrue();
    myData = json.decode(temp);
    numbTrue = new List<int>.generate(myData.length, (int index) => index);
    numbTrue.shuffle();
    for(int i = 0; i < numbOfTrue - numbOfStandard; i++){ //replace 5 by numbOfTrue when use
      questionsModel tempQuestion = new questionsModel("true/" + myData[numbTrue.elementAt(i)]["question_name"].toString(), myData[numbTrue.elementAt(i)]["answer"].toString());
      questionsList.add(tempQuestion);
    }
  }

  void loadQuestionFalse() async {
    String temp = await loadJsonFalse();
    myData = json.decode(temp);
    numbFalse = new List<int>.generate(myData.length, (int index) => index);
    numbFalse.shuffle();
    for(int i = 0; i < numbOfFalse; i++){ //replace 5 by numbOfTrue when use
      questionsModel tempQuestion = new questionsModel("false/" + myData[numbFalse.elementAt(i)]["question_name"].toString(), myData[numbFalse.elementAt(i)]["answer"].toString());
      questionsList.add(tempQuestion);
    }
  }

  void loadQuestionStandard() async {
    String temp = await loadJsonStandard();
    myData = json.decode(temp);
    numbStandard = new List<int>.generate(myData.length, (int index) => index);
    numbStandard.shuffle();
    for(int i = 0; i < numbOfStandard; i++){ //replace 5 by numbOfTrue when use
      questionsModel tempQuestion = new questionsModel("standard/" + myData[numbStandard.elementAt(i)]["question_name"].toString(), myData[numbStandard.elementAt(i)]["answer"].toString());
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

  Future<bool> _onBackPressed (){
    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: Text(question),
        actions: <Widget>[
          new RaisedButton.icon(
            icon: Icon(Icons.close, color: Colors.white,),
            label: Text(no, style: TextStyle(color: Colors.white),),
            onPressed: () => Navigator.of(context).pop(false),
            elevation: 0.0,
            color: Colors.redAccent,
          ),
          new RaisedButton.icon(
            icon: Icon(Icons.exit_to_app, color: Colors.white,),
            label: Text(yes, style: TextStyle(color: Colors.white),),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            elevation: 0.0,
            color: Colors.green,
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    question = Translations.of(context).text("dialog_cancel_test");
    yes = Translations.of(context).text("dialog_yes");
    no = Translations.of(context).text("dialog_no");
    // TODO: implement build
    return MediaQuery.removePadding(
      context: context,
      child: WillPopScope(
          child: Scaffold(
            appBar: AppBar(
              title: Text(Translations.of(context).text('do_test_question') + (currentPlaying + 1).toString() + "/10"),
              backgroundColor: Colors.cyan,
            ),
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
          onWillPop: _onBackPressed,
      ),
      removeTop: true,
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