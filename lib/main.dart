import 'dart:async';

import 'package:easy_send_sms/easy_sms.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Multi SMS Sender'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final _easySmsPlugin = EasySms();

  String _phone = '';
  String _msg = '';
  int _repeatCount = 0;
  int _interval = 5; // in seconds

  int _doneCount = 0;
  int _failedCount = 0;

  bool _stopSending = true;
  bool _isSending = false;

  bool isValidPhoneNumber(String s) {
    final RegExp regExp = RegExp(r'^(\+?\d{1,3}\d{6,14}|^\d{3,5})$');
    return regExp.hasMatch(s);
  }

  Future<void> _sendSms({required String phone, required msg}) async {
    _isSending = true;

    try {
      await _easySmsPlugin.requestSmsPermission();
      await _easySmsPlugin.sendSms(phone: phone, msg: msg);
    } catch (err) {
      _failedCount++;
      print(err.toString());
    }

    _doneCount++;
    _isSending = false;

    if (_doneCount >= _repeatCount) {
      _stopSending = true;
    }

    setState(() {});
  }

  void _startSending() {
    setState(() {
      _stopSending = false;
    });

    Timer.periodic(Duration(seconds: _interval), (timer) {
      if (_stopSending) {
        timer.cancel();
        return;
      }

      if (_isSending) return;

      _sendSms(phone: _phone, msg: _msg);
    });
  }

  void _reset() {
    _doneCount = 0;
    _failedCount = 0;
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        setState(() {
          if (!_stopSending) _stopSending = true;
        });
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
        /*setState(() {
          if (!_stopSending) _stopSending = true;
        });*/
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                onChanged: (value) {
                  if (isValidPhoneNumber(value)) {
                    _phone = value;
                  } else {
                    _phone = '';
                  }

                  setState(() {});
                },
                readOnly: !_stopSending,
                decoration: const InputDecoration(
                  hintText: "Destination (ex: +94770000000)",
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                onChanged: (value) {
                  _msg = value.trim();
                  setState(() {});
                },
                readOnly: !_stopSending,
                decoration: const InputDecoration(
                  hintText: "Type text message here",
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                onChanged: (value) {
                  int? val = int.tryParse(value);

                  if (val == null) {
                    _repeatCount = 0;
                  } else {
                    _repeatCount = val;
                  }

                  setState(() {});
                },
                readOnly: !_stopSending,
                decoration: const InputDecoration(
                  hintText: "Repeat Count (ex: 100)",
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Interval:", style: TextStyle(fontSize: 10)),
                      DropdownButton<String>(
                        hint: const Text('Select Time'),
                        value: '$_interval secs',
                        onChanged: (String? newValue) {
                          if (newValue == null) {
                            _interval = 0;
                          } else {
                            _interval =
                                int.parse(newValue.replaceFirst(' secs', ''));
                          }

                          setState(() {});
                        },
                        items: <String>['5 secs', '10 secs', '15 secs']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  _repeatCount > 0 && _doneCount == _repeatCount
                      ? const Text(
                          "Done!",
                          style: TextStyle(color: Colors.green, fontSize: 20),
                        )
                      : FilledButton(
                          onPressed: (_phone.isEmpty ||
                                  _msg.isEmpty ||
                                  _repeatCount == 0)
                              ? null
                              : () {
                                  if (_stopSending) {
                                    _startSending();
                                  } else {
                                    _stopSending = true;
                                  }

                                  setState(() {});
                                },
                          child: Text(_stopSending ? "Start" : "Stop"),
                        ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: !_stopSending
                        ? null
                        : () {
                            _reset();
                          },
                    child: const Text("Reset"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Sent: ${(_doneCount - _failedCount)}  |  Failed: $_failedCount",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
