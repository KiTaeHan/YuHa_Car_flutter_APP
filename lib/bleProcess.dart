import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'JoystickScreen.dart';

class BleProcess extends StatefulWidget {
  BleProcess({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _BleProcessState createState() => _BleProcessState();
}

class _BleProcessState extends State<BleProcess> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder<BluetoothState>(
        stream: FlutterBlue.instance.state,
        initialData: BluetoothState.unknown,
        builder: (context, snapshot) {
          final state = snapshot.data;
          if (state == BluetoothState.on) {
            return FindDeviceScreen(title: widget.title,);
          } else {
            return BleOffScreen(
              state: state,
            );
          }
        },
      ),
    );
  }
}

class BleOffScreen extends StatelessWidget {
  const BleOffScreen({Key key, this.state}) : super(key: key);
  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth is ${state != null ? state.toString().substring(15) : 'not available'}',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subtitle1
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class FindDeviceScreen extends StatefulWidget {
  FindDeviceScreen({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _FindDeviceScreenState createState() => _FindDeviceScreenState();
}

class _FindDeviceScreenState extends State<FindDeviceScreen> {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> deviceList = List<BluetoothDevice>();

  void _addBTDeviceToList(BluetoothDevice device) {
    for (int i = 0; i < deviceList.length; i++) {
      if (deviceList[i].id == device.id) {
        return;
      }
    }

    print("device hash code: ${device.hashCode}");
    print("device id: ${device.id}");
    print("device mtu: ${device.mtu}");
    print("device name: ${device.name}");
    if (device.name.length > 0) deviceList.add(device);
  }

  void _searchPressed() async {
    deviceList.clear();
    await flutterBlue.startScan(timeout: Duration(seconds: 4));
    flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult ret in results) {
        if (ret.device.id != null) _addBTDeviceToList(ret.device);
      }
    });
    flutterBlue.stopScan();
    setState(() {});
  }

  Future<List<Widget>> _getItems(BuildContext context) async {
    List<Card> cards = List<Card>();

    if (deviceList.length > 0) {
      for (BluetoothDevice device in deviceList) {
        cards.add(Card(
          margin: EdgeInsets.all(8.0),
          child: ListTile(
            leading: Icon(Icons.bluetooth),
            title: Text(device.name.toString()),
            trailing: (device.name == 'YuHa Car') ? Icon(Icons.play_circle_outline) : null,
            onTap: (){
              if(device.name == 'YuHa Car') {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>JoystickScreen(bledevice: device,)));
              }
            },
          ),
        ));
      }

      return cards;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 150.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.title),
              centerTitle: true,
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.search),
                onPressed: _searchPressed,
              )
            ],
          ),
          FutureBuilder(
            future: _getItems(context),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return SliverList(
                  delegate: SliverChildListDelegate(snapshot.data),
                );
              } else {
                return SliverToBoxAdapter(
                  child: Center(
                    //child: CircularProgressIndicator(),
                    child: Text('No BT device'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
