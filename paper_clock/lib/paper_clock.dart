import 'dart:async';

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:paper_clock/paper_canvas.dart';
import 'package:paper_clock/sun_rise_set.dart';

class PaperClock extends StatefulWidget {
  const PaperClock(this.model);

  final ClockModel model;

  @override
  _PaperClockState createState() => _PaperClockState();
}

class _PaperClockState extends State<PaperClock> {
  var _now = DateTime.now();
  var _temperature;
  var _tempUnits = TemperatureUnit.celsius;
  var _tempUnitString = "";
  var _condition;
  Timer _timer;
  bool _is24Hour = false;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(PaperClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _tempUnits = widget.model.unit;
      _tempUnitString = widget.model.unitString;
      _temperature = widget.model.temperature;
      _condition = widget.model.weatherCondition;
      _is24Hour = widget.model.is24HourFormat;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  double _convertToCelsius(double temp) {
    if (_tempUnits == TemperatureUnit.celsius) {
      return temp;
    } else {
      return (temp - 32.0) * 5.0 / 9.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.Hm().format(DateTime.now());
    final time = DateTime.now();

    //TODO: Get the real sunset and sunrise
    /* Note: This is where we would get or calculate the sunrise and sunset.
    To calculate the sunrise/set, you need to know the latitude and longitude of
    the device.  Right now, we only get a location string.  We could use that
    string to get the an approximate lat/lon (using the state or country),
    but it might not be reliable.  For the contest, I'll simply hard-code the
    position to Mountain View, CA.
     */
    double latitude = 37.421555; //TODO: get real latitude from device
    double longitude = -122.083977; //TODO: get real longitude from device
    int utcOffset =
        -8; //TODO: replace with DateTime.now().timeZoneOffset.inHours;
    int dayOfYear = int.parse(DateFormat("D").format(DateTime.now()));
    double sunset = SunRiseSetAlgo.calcSunset(
        dayOfYear, utcOffset.toDouble(), latitude, longitude);
    double sunrise = SunRiseSetAlgo.calcSunrise(
        dayOfYear, utcOffset.toDouble(), latitude, longitude);

    /*Create the temperature string. The model contains one, but degrees
    probably doesn't need a decimal place.
     */
    String temperatureString =
        _temperature.toStringAsFixed(0) + _tempUnitString;

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Paper Clock with time $time',
        value: timeFormat,
      ),
      child: new LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        return CustomPaint(
            painter: new PaperCanvas(time, sunrise, sunset, _condition,
                _convertToCelsius(_temperature), _is24Hour, temperatureString),
            size: constraints.widthConstraints().biggest);
      }),
    );
  }
}
