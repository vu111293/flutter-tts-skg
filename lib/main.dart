import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;


void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

enum TtsState { playing, stopped }

class _MyAppState extends State<MyApp> {
  FlutterTts flutterTts;
  dynamic languages;
  dynamic voices;
  String language;
  String voice;
  int silencems;

  String _newVoiceText;

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;

  get isStopped => ttsState == TtsState.stopped;

  @override
  initState() {
    super.initState();
    initTts();
  }

  initTts() {
    flutterTts = FlutterTts();
    _getLanguages();
    _getVoices();

    if (Platform.isAndroid) {
      flutterTts.ttsInitHandler(() {
        _getLanguages();
        _getVoices();
      });
    } else if (Platform.isIOS) {
      _getLanguages();
      _getVoices();
    }

    flutterTts.setLanguage('ja-JP');
    flutterTts.setStartHandler(() {
      setState(() {
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });
  }

  Future _getLanguages() async {
    languages = await flutterTts.getLanguages;
    (languages as List).forEach((item) => print(item));
    if (languages != null) setState(() => languages);
  }

  Future _getVoices() async {
    voices = await flutterTts.getVoices;
    if (voices != null) setState(() => voices);
  }

  Future _speak() async {
    if (_newVoiceText != null) {
      if (_newVoiceText.isNotEmpty) {
        var result = await flutterTts.speak(_newVoiceText);
        if (result == 1) setState(() => ttsState = TtsState.playing);
      }
    }
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future _convertAudio() async {
//    if (_newVoiceText != null) {
//      if (_newVoiceText.isNotEmpty) {

    List<String> files = ['0203','0204', '0205', '0206', '0207', '0208', '0209', '0210']
        .map((item) => 'DSC_$item')
        .toList();


    for (int i = 0; i < files.length; ++i) {
      String text = await rootBundle.loadString('assets/${files.elementAt(i)}.txt');
      Directory audioPath = await getExternalStorageDirectory();
      String path = audioPath.path + "/${files.elementAt(i)}.mp3";

      await Future.delayed(Duration(seconds: 1));
      int done = await flutterTts.getAudioFile(text, path);
      print('${done == 1 ? 'Sucess conv' : 'Conv error'} for ${files.elementAt(i)}');
    }
//      }
//    }
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems() {
    var items = List<DropdownMenuItem<String>>();
    for (String type in languages) {
      items.add(DropdownMenuItem(value: type, child: Text(type)));
    }
    return items;
  }

  List<DropdownMenuItem<String>> getVoiceDropDownMenuItems() {
    var items = List<DropdownMenuItem<String>>();
    for (String type in voices) {
      items.add(DropdownMenuItem(value: type, child: Text(type)));
    }
    return items;
  }

  List<DropdownMenuItem<int>> getSilenceDropDownMenuItems() {
    var items = List<DropdownMenuItem<int>>();
    items.add(DropdownMenuItem(value: null, child: Text("No Silence before TTS")));
    items.add(DropdownMenuItem(value: 1000, child: Text("1 Second Silence before TTS")));
    items.add(DropdownMenuItem(value: 5000, child: Text("5 Seconds Silence before TTS")));
    return items;
  }

  void changedLanguageDropDownItem(String selectedType) {
    setState(() {
      language = selectedType;
      flutterTts.setLanguage(language);
    });
  }

  void changedVoiceDropDownItem(String selectedType) {
    setState(() {
      voice = selectedType;
      flutterTts.setVoice(voice);
    });
  }

  void changedSilenceDropDownItem(int selectedType) {
    setState(() {
      silencems = selectedType;
      flutterTts.setSilence(silencems);
    });
  }

  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: Text('Flutter TTS'),
            ),
            body: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(children: [
                  inputSection(),
                  btnSection(),
                  languages != null ? languageDropDownSection() : Text(""),
                  voices != null ? voiceDropDownSection() : Text(""),
                  Platform.isAndroid ? silenceDropDownSection() : Text("")
                ]))));
  }

  Widget inputSection() => Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0),
      child: TextField(
        onChanged: (String value) {
          _onChange(value);
        },
      ));

  Widget btnSection() => Container(
      padding: EdgeInsets.only(top: 50.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _buildButtonColumn(Colors.green, Colors.greenAccent, Icons.play_arrow, 'PLAY', _speak),
        _buildButtonColumn(Colors.red, Colors.redAccent, Icons.stop, 'STOP', _stop),
        _buildButtonColumn(Colors.blue, Colors.blueAccent, Icons.audiotrack, 'AUDIO', _convertAudio),
      ]));

  Widget languageDropDownSection() => Container(
      padding: EdgeInsets.only(top: 50.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          value: language,
          items: getLanguageDropDownMenuItems(),
          onChanged: changedLanguageDropDownItem,
        )
      ]));

  Widget voiceDropDownSection() => Container(
      padding: EdgeInsets.only(top: 30.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          value: voice,
          items: getVoiceDropDownMenuItems(),
          onChanged: changedVoiceDropDownItem,
        )
      ]));

  Widget silenceDropDownSection() => Container(
      padding: EdgeInsets.only(top: 30.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          value: silencems,
          items: getSilenceDropDownMenuItems(),
          onChanged: changedSilenceDropDownItem,
        )
      ]));

  Column _buildButtonColumn(Color color, Color splashColor, IconData icon, String label, Function func) {
    return Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(icon: Icon(icon), color: color, splashColor: splashColor, onPressed: () => func()),
      Container(
          margin: const EdgeInsets.only(top: 8.0),
          child: Text(label, style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400, color: color)))
    ]);
  }
}
