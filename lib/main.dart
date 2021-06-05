import 'package:flutter/material.dart';
import 'package:flutter_flashlight/flutter_flashlight.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        scaffoldBackgroundColor: Colors.white70
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String state = "disconnected";
  MqttServerClient client;
  bool hasFlashlight = false;
  bool FlashlightOn = false;

  @override
  void initState() {
    super.initState();
    initFlashLight();
  }

  void initFlashLight() async {
    hasFlashlight = await Flashlight.hasFlashlight;
    print("********** Device has flashlight **********");
    setState(() {});
  }

  void startFlashlight() {
    Flashlight.lightOn();
    FlashlightOn = true;
    setState(() {});
  }

  void connect() async {
    client = MqttServerClient.withPort('broker.emqx.io', 'flutter_client_2', 1883);
    client.logging(on: true);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }
    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload;
      final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      print("********** The received message: $payload **********");
      startFlashlight();
    });
    client.subscribe("flashlightapp/mytopic", MqttQos.atLeastOnce);
  }

  void disconnect() {
    this.client.disconnect();
  }

  void onConnected() {
    state = "connected";
    setState(() {});
  }

  void onDisconnected() {
    state = "disconnected";
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.all(39.0),
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 5)
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget> [
                        Text('Flashlight: ', style: TextStyle(fontSize: 20, color: Colors.black),),
                        if (FlashlightOn == false)
                          Text('OFF', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),)
                        else if (FlashlightOn == true)
                          Text('ON', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),)
                      ]
                  ),
                ),
                SizedBox(height: 80),
                ElevatedButton(
                  onPressed: () {
                    if (state == "disconnected")
                      connect();
                    else if (state == "connected")
                      disconnect();
                  },
                  child: SizedBox(
                    width: 280.0,
                    child: Row (
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget> [
                          if (state == "disconnected")
                            Text('CONNECT TO THE MQTT BROKER', style: TextStyle(fontSize: 18, color: Colors.white))
                          else if (state == "connected")
                            Text('DISCONNECT FROM THE BROKER', style: TextStyle(fontSize: 18, color: Colors.white))
                        ]
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.green,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget> [
                      Text('Status: ', style: TextStyle(fontSize: 20, color: Colors.black),),
                      if (state == "disconnected")
                        Text('DISCONNECTED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),)
                      else if (state == "connected")
                        Text('CONNECTED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),)
                    ]
                )
              ],
            ),
          ),
        ],
      )
    );
  }
}
