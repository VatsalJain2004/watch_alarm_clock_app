import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:wear/wear.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: WearAlarmApp(),
  ));
}

class AlarmItem {
  final TimeOfDay time;
  bool isEnabled;

  AlarmItem(this.time, this.isEnabled);
}

class WearAlarmApp extends StatefulWidget {
  const WearAlarmApp({super.key});

  @override
  State<WearAlarmApp> createState() => _WearAlarmAppState();
}

class _WearAlarmAppState extends State<WearAlarmApp> {
  late Timer alarmChecker;
  final AudioPlayer _player = AudioPlayer();
  List<AlarmItem> alarms = [];

  @override
  void initState() {
    super.initState();
    loadAlarms().then((_) {
      setState(() {}); // Ensures UI updates after loading
    });

    Timer.periodic(
        const Duration(
          seconds: 1,
        ), (timer) {
      final now = TimeOfDay.now();
      for (var alarm in alarms) {
        if (alarm.time.hour == now.hour && alarm.time.minute == now.minute && alarm.isEnabled == true) {
          startAlarm();
          print(now);
          break;
        }
      }
    });
  }

  void startAlarm() async {
    await _player.play(AssetSource('ringtones/newday.mp3'));
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(
          pattern: [0, 500, 1000, 500, 1000],
          repeat: 0); // vibrate with a pattern
    }
    Future.delayed(const Duration(minutes: 1), () {
      _player.stop();
    });
  }

  @override
  void dispose() {
    alarmChecker.cancel();
    super.dispose();
  }

  Future<void> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? alarmStrings = prefs.getStringList('alarms');

    if (alarmStrings != null) {
      alarms = alarmStrings.map((alarmString) {
        final parts = alarmString.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final isEnabled = parts.length > 2 ? parts[2] == 'true': true;

        return AlarmItem(TimeOfDay(hour: hour, minute: minute), isEnabled);
      }).toList();
      print('Loaded alarms: $alarms');
    }
  }

  Future<void> saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> alarmStrings = alarms
        .map(
            (alarm) => '${alarm.time.hour}:${alarm.time.minute}'
    ).toList();
    await prefs.setStringList('alarms', alarmStrings);

    print('Saved alarms: $alarmStrings');
  }

  Future<TimeOfDay?> _showTimePicker(BuildContext context, int index) async {
    TimeOfDay selectedTime;
    if(index == -1){
      selectedTime = TimeOfDay.now();
    }
    else{
      selectedTime = alarms[index].time;
    }
    int hour = selectedTime.hourOfPeriod == 0 ? 12 : selectedTime.hourOfPeriod;
    int minute = selectedTime.minute;
    bool isAM = selectedTime.period == DayPeriod.am;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(16),
              content: SizedBox(
                width: screenWidth * 0.5,
                height: screenHeight * 0.5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Time Pickers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NumberPicker(
                          minValue: 1,
                          maxValue: 12,
                          value: hour,
                          onChanged: (val) => setState(() => hour = val),
                          textStyle: const TextStyle(
                              color: Colors.white30, fontSize: 0),
                          selectedTextStyle: const TextStyle(
                              color: Colors.white, fontSize: 20),
                          infiniteLoop: true,
                          itemWidth: 30,
                          itemHeight: 20,
                        ),
                        const SizedBox(
                          width: 10,
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        NumberPicker(
                          minValue: 0,
                          maxValue: 59,
                          value: minute,
                          zeroPad: true,
                          onChanged: (val) => setState(() => minute = val),
                          textStyle: const TextStyle(
                              color: Colors.white30, fontSize: 0),
                          selectedTextStyle: const TextStyle(
                              color: Colors.white, fontSize: 20),
                          itemWidth: 30,
                          itemHeight: 20,
                          infiniteLoop: true,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => isAM = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 5),
                                decoration: BoxDecoration(
                                  color:
                                  isAM ? Colors.blue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text("AM",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => setState(() => isAM = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 5),
                                decoration: BoxDecoration(
                                  color:
                                  !isAM ? Colors.blue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text("PM",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close,
                              color: Colors.red, size: 30),
                        ),
                        GestureDetector(
                          onTap: () {
                            final adjustedHour = isAM
                                ? (hour == 12 ? 0 : hour)
                                : (hour == 12 ? 12 : hour + 12);
                            final selectedTime =
                            TimeOfDay(hour: adjustedHour, minute: minute);
                            Navigator.pop(context, selectedTime);
                          },
                          child: const Icon(Icons.check,
                              color: Colors.blue, size: 30),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Container(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5.0,),
                  child: GestureDetector(
                    onTap: () async {
                      final TimeOfDay? newAlarm = await
                      _showTimePicker(context, -1);
                      if (newAlarm != null) {
                        setState(() {
                          alarms.add(AlarmItem(newAlarm, true));
                        });
                        await saveAlarms();
                      }
                    },
                    child: Container(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.alarm_add,
                            size: 30,
                            color: Colors.white,
                          ),
                          Text(
                            'Alarm',
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.lightGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: alarms.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, index) {
                      final alarm = alarms[index].time;
                      final hour = alarm.hourOfPeriod == 0 ? 12 : alarm.hourOfPeriod;
                      final minute = alarm.minute.toString().padLeft(2, '0');
                      final period = alarm.period == DayPeriod.am ? "AM" : "PM";

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xFF0E0E0E),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 3.5, horizontal: 10),
                            title: Row(
                              children: [
                                Text(
                                  '$hour:$minute',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w400),
                                ),
                                Text(
                                  ' $period',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 18),
                                ),
                              ],
                            ),
                            onTap: () async {
                              final TimeOfDay? newAlarm = await
                              _showTimePicker(context, index);
                              if (newAlarm != null) {
                                setState(() {
                                  alarms[index] = AlarmItem(newAlarm, true);
                                });
                                await saveAlarms();
                              }
                            },
                            onLongPress: () async {
                              setState(() {
                                alarms.removeAt(index);
                              });
                              await saveAlarms();
                            },
                            trailing: Switch(
                              value: alarms[index].isEnabled,
                              onChanged: (value) async {
                                alarms[index].isEnabled = !alarms[index].isEnabled;
                                setState(() {
                                  alarms;
                                });
                                await alarms;
                              },
                              activeColor: Colors.green,
                              activeTrackColor: Colors.green.shade200,
                              inactiveTrackColor: Colors.white10,
                              inactiveThumbColor: Colors.white54,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}