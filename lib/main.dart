import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_admob/firebase_admob.dart';

void main(){
  runApp(MaterialApp(

      home: Home(),

  ));
  
}
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoController = TextEditingController();

  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;


  @override
  void initState() {
    super.initState();
    _readData().then((data){
    setState(() {
    _toDoList = json.decode(data);
    });
    });

  }

  void addToDo(){
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }
  Future<Null> _refresh ()async{
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b){
        if(a["ok"] && !b["ok"]) return 1;
        else if (!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
      _saveData();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAdMob.instance.initialize(appId: "ca-app-pub-1396334732722035~3261812100");
    myBanner
    // typically this happens well before the ad is shown
      ..load()
      ..show(
        // Positions the banner ad 60 pixels from the bottom of the screen
        anchorOffset: 60.0,
        // Positions the banner ad 10 pixels from the center of the screen to the right
        horizontalCenterOffset: 10.0,
        // Banner Position
        anchorType: AnchorType.bottom,
      );
     myInterstitial
      ..load()
      ..show(
        anchorType: AnchorType.bottom,
        anchorOffset: 0.0,
        horizontalCenterOffset: 0.0,
      );
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Compras"),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
       ),
      body: Column(

        children: <Widget>[
          Container(

            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Novo Item",
                        labelStyle: TextStyle(color: Colors.black)
                    ),
                  ),

            ),
                RaisedButton(
                  color: Colors.redAccent,
                  child: Icon(Icons.add, color: Colors.white),
                  //textColor: Colors.white,
                  onPressed: addToDo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
                ),
            )
        ],
      ),
    );
  }
  Widget buildItem(context, index){
      return Dismissible(
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(Icons.delete, color: Colors.white),
          ),
        ),
        direction: DismissDirection.startToEnd,
        child:  CheckboxListTile(
            title: Text(_toDoList[index]["title"]),
            value: _toDoList[index]["ok"],
            secondary: CircleAvatar(
              child: Icon(_toDoList[index]["ok"]?
              Icons.check : Icons.error
              ),
            ),
            onChanged: (c) {
              setState(() {
                _toDoList[index]["ok"] = c;
                _saveData();
              },
              );
            }),
        onDismissed: (direction){
          setState(() {
            _lastRemoved = Map.from(_toDoList[index]);
            _lastRemovedPos = index;
            _toDoList.removeAt(index);
            _saveData();
            final snack = SnackBar(
              content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
              action: SnackBarAction(label: "Desfazer",
              onPressed: (){
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });

              },),
              duration: Duration(seconds: 2),
            );
            Scaffold.of(context).removeCurrentSnackBar();
            Scaffold.of(context).showSnackBar(snack);
          });

        },
      );
  }



  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }
  Future<String> _readData()async{
    try{
      final file = await _getFile();
      return file.readAsString();
    }catch(e){
      return null;

    }
  }

}
MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
  keywords: <String>['Ferramenta', 'Compras'],
  contentUrl: 'https://flutter.io',
  childDirected: false,
  testDevices: <String>[], // Android emulators are considered test devices
);
BannerAd myBanner = BannerAd(
  // Replace the testAdUnitId with an ad unit id from the AdMob dash.
  // https://developers.google.com/admob/android/test-ads
  // https://developers.google.com/admob/ios/test-ads
  adUnitId: "ca-app-pub-1396334732722035/7217654397",
  size: AdSize.smartBanner,
  targetingInfo: targetingInfo,
  listener: (MobileAdEvent event) {
    print("BannerAd event is $event");
  },
);

InterstitialAd myInterstitial = InterstitialAd(
  // Replace the testAdUnitId with an ad unit id from the AdMob dash.
  // https://developers.google.com/admob/android/test-ads
  // https://developers.google.com/admob/ios/test-ads
  adUnitId: "ca-app-pub-1396334732722035/4383322083",
  targetingInfo: targetingInfo,
  listener: (MobileAdEvent event) {
    print("InterstitialAd event is $event");
  },
);