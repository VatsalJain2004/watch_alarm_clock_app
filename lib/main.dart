import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wear/wear.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: WearAlarmApp(),
  ));
}

class WearAlarmApp extends StatefulWidget {
  const WearAlarmApp({super.key});

  @override
  State<WearAlarmApp> createState() => _WearAlarmAppState();
}

class _WearAlarmAppState extends State<WearAlarmApp> {
  List<TimeOfDay> alarms = [];

  @override
  void initState() {
    super.initState();
    loadAlarms().then((_) {
      setState(() {}); // Ensures UI updates after loading
    });
  }

  Future<void> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? alarmStrings = prefs.getStringList('alarms');

    if (alarmStrings != null) {
      alarms = alarmStrings.map((alarmString) {
        final parts = alarmString.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
    }

    print('Loaded alarms: $alarms');
  }

  Future<void> saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> alarmStrings = alarms
        .map((alarm) => '${alarm.hour}:${alarm.minute}')
        .toList();
    await prefs.setStringList('alarms', alarmStrings);

    print('Saved alarms: $alarmStrings');
  }

  Future<TimeOfDay?> _showTimePicker(BuildContext context) async {
    TimeOfDay selectedTime = TimeOfDay.now();
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
                          textStyle: const TextStyle(color: Colors.white30, fontSize: 0),
                          selectedTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
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
                          textStyle: const TextStyle(color: Colors.white30, fontSize: 0),
                          selectedTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
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
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isAM ? Colors.blue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text("AM", style: TextStyle(color: Colors.white, fontSize: 15)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => setState(() => isAM = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                decoration: BoxDecoration(
                                  color: !isAM ? Colors.blue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text("PM", style: TextStyle(color: Colors.white, fontSize: 15)),
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
                          child: const Icon(Icons.close, color: Colors.red, size: 30),
                        ),
                        GestureDetector(
                          onTap: () {
                            final adjustedHour = isAM
                                ? (hour == 12 ? 0 : hour)
                                : (hour == 12 ? 12 : hour + 12);
                            final selectedTime = TimeOfDay(hour: adjustedHour, minute: minute);
                            Navigator.pop(context, selectedTime);
                          },
                          child: const Icon(Icons.check, color: Colors.blue, size: 30),
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
          backgroundColor: Colors.lightGreenAccent.shade700,
          body: Container(
            width: double.infinity,
            child: Column(
              children: [
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final TimeOfDay? newAlarm = await _showTimePicker(context);
                    if (newAlarm != null) {
                      setState(() {
                        alarms.add(newAlarm);
                      });
                      await saveAlarms();
                    }
                  },
                  child: const Icon(Icons.alarm, size: 50, color: Colors.white),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: alarms.length,
                    itemBuilder: (context, index) {
                      final alarm = alarms[index];
                      final hour = alarm.hourOfPeriod == 0 ? 12 : alarm.hourOfPeriod;
                      final minute = alarm.minute.toString().padLeft(2, '0');
                      final period = alarm.period == DayPeriod.am ? "AM" : "PM";

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          tileColor: Colors.transparent,
                          leading: const Icon(Icons.access_alarm, color: Colors.red),
                          title: Text(
                            '$hour:$minute $period',
                            style: const TextStyle(color: Colors.red, fontSize: 20),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () async {
                              setState(() {
                                alarms.removeAt(index);
                              });
                              await saveAlarms();
                            },
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
