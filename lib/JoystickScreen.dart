import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:control_pad/control_pad.dart';
import 'package:flutter_blue/flutter_blue.dart';

class JoystickScreen extends StatefulWidget {
  JoystickScreen({Key key, this.bledevice}) : super(key: key);
  final BluetoothDevice bledevice;

  @override
  _JoystickScreenState createState() => _JoystickScreenState();
}

class _JoystickScreenState extends State<JoystickScreen> {
  static const YUHA_CAR_SPP_UUID = "6d086b8d-3ca0-4717-a568-22efd5a755f5";
  static const YUHA_CAR_SPP_UUID_TX = "ea88579f-e518-416b-8cea-1085e88e4694";

  double degreesToRadians(double degrees) => (degrees * pi) / 180.0;
  List<BluetoothService> _services;
  BluetoothCharacteristic _sppCharacter;

  int _prel = 0;
  int _prer = 0;

  Future<bool> _bleDeviceConnect() async {
    bool deviceConnected = false;

    try {
      await widget.bledevice.connect();
    } catch (e) {
      if (e.code != 'already_connected') {
        throw e;
      }
    } finally {
      deviceConnected = true;
      _services = await widget.bledevice.discoverServices();
      print("device connected !");
    }

    return deviceConnected;
  }

  ListView _buildConnectDevcieView() {
    List<Container> containers = List<Container>();

    _services.forEach((element) {
      List<Widget> characteristicsWidgt = List<Widget>();
      for (BluetoothCharacteristic characteristic in element.characteristics) {
        characteristic.value.listen((event) {
          print("~~~ $event");
        });
        //print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        //print(characteristic.properties.toString());
        //print(characteristic.uuid.toString());
        if (characteristic.uuid.toString() == YUHA_CAR_SPP_UUID_TX) {
          _sppCharacter = characteristic;
          characteristicsWidgt.add(Align(
            alignment: Alignment.centerLeft,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      characteristic.uuid.toString(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Divider(),
              ],
            ),
          ));
        }
      }
      if (element.uuid.toString() == YUHA_CAR_SPP_UUID) {
        containers.add(
          Container(
            child: ExpansionTile(
              title: Text(element.uuid.toString()),
              children: characteristicsWidgt,
            ),
          ),
        );
      }
    });

    return ListView(
      padding: EdgeInsets.all(8.0),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conrol Pad Example'),
      ),
      body: FutureBuilder(
        future: _bleDeviceConnect(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(child: _buildConnectDevcieView()),
                Container(
                  child: JoystickView(
                    onDirectionChanged: (degrees, distance) async {
                      // print("degress: $degrees");
                      // print("Radians: ${degreesToRadians(degrees)}");
                      // print("cos: ${cos(degreesToRadians(degrees))}");
                      // print("sin: ${sin(degreesToRadians(degrees))}");
                      // print('distance: $distance');
                      Future.delayed(Duration(microseconds: 300), () {});
                      var xraw = cos(degreesToRadians(degrees)) * distance;
                      var yraw = sin(degreesToRadians(degrees)) * distance;
                      // reverse x,y => y,x
                      var y = (xraw * 5).toInt();
                      var x = (yraw * 5).toInt();
                      print("($x,$y)");

                      int l, r;
                      if ((degrees > 0) && (degrees < 90)) {
                        l = 10;
                        r = 10 - x;
                        // print("0~90: l [$l], r [$r]");
                      } else if ((degrees > 90) && (degrees < 180)) {
                        l = 1;
                        r = x + 1;
                        // print("90~180: l [$l], r [$r]");
                      } else if ((degrees > 180) && (degrees < 270)) {
                        r = 1;
                        l = (x * -1) + 1;
                        // print("180~270: l [$l], r [$r]");
                      } else if ((degrees > 270) && (degrees < 360)) {
                        r = 10;
                        l = 10 + x;
                        // print("270~360: l [$l], r [$r]");
                      }

                      if ((x == 0) && (y == 0)) {
                        l = 0;
                        r = 0;
                      }

                      if ((_prel != l) || (_prer != r)) {
                        _prel = l;
                        _prer = r;
                        print("l [$l], r [$r]");
                        List<int> senddata = ascii.encode("l$l:r$r");
                        //print(senddata.runtimeType);
                        //print(senddata);
                        await _sppCharacter.write(senddata,
                            withoutResponse: true);
                      }
                    },
                  ),
                ),
              ],
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
