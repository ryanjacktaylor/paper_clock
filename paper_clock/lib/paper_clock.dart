import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as Math;

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:paper_clock/SunRiseSet.dart';
import 'package:path_drawing/path_drawing.dart';
import 'SunRiseSet.dart';

class PaperClock extends StatefulWidget {
  const PaperClock(this.model);

  final ClockModel model;

  @override
  _PaperClockState createState() => _PaperClockState();
}

class _PaperClockState extends State<PaperClock> {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  Timer _timer;

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
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
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

  @override
  Widget build(BuildContext context) {
    // There are many ways to apply themes to your clock. Some are:
    //  - Inherit the parent Theme (see ClockCustomizer in the
    //    flutter_clock_helper package).
    //  - Override the Theme.of(context).colorScheme.
    //  - Create your own [ThemeData], demonstrated in [AnalogClock].
    //  - Create a map of [Color]s to custom keys, demonstrated in
    //    [DigitalClock].
    final customTheme = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).copyWith(
            // Hour hand.
            primaryColor: Color(0xFF4285F4),
            // Minute hand.
            highlightColor: Color(0xFF8AB4F8),
            // Second hand.
            accentColor: Color(0xFF669DF6),
            backgroundColor: Color(0xFFD2E3FC),
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFFD2E3FC),
            highlightColor: Color(0xFF4285F4),
            accentColor: Color(0xFF8AB4F8),
            backgroundColor: Color(0xFF3C4043),
          );

    final timeFormat = DateFormat.Hm().format(DateTime.now());
    final time = DateTime.now();
    final weatherInfo = DefaultTextStyle(
      style: TextStyle(color: customTheme.primaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_temperature),
          Text(_temperatureRange),
          Text(_condition),
          Text(_location),
        ],
      ),
    );

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
    double temp = sunset;

    //Calculate the size of the CustomPaint
    double paintHeight = MediaQuery.of(context).size.height;

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Paper Clock with time $time',
        value: timeFormat,
      ),
      child: new LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        return CustomPaint(
            painter: new PaperCanvas(time, sunrise, sunset),
            size: constraints.widthConstraints().biggest);
      }),
    );
  }
}

class PaperCanvas extends CustomPainter {
  final DateTime time;
  final sunrise;
  final sunset;

  PaperCanvas(this.time, this.sunrise, this.sunset);

  @override
  void paint(Canvas canvas, Size size) {
    double timeInHours = time.hour + time.minute / 60.0 + time.second / 3600;
    Offset sunPosition = new Offset(
        size.width / 2, getSunMoonPosition(timeInHours, sunset, sunrise, size));
    double sunRadius = 70.0 * size.height / 524;

    //Check if it's day or night
    bool isDayTime = timeInHours > sunrise && timeInHours < sunset;

    //Draw the sky background
    Paint skyPaint =
        getSkyPaint(timeInHours, sunrise, sunset, size, sunPosition);
    Rect skyRect = new Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(skyRect);  //Prevents overflow beyond border
    canvas.drawRect(skyRect, skyPaint);

    //Draw the stars
    if (!isDayTime) {
      drawStar(
          canvas,
          timeInHours,
          sunrise,
          sunset,
          Offset(size.width * .1, size.height * .5),
          15,
          -.3);
      drawStar(
          canvas,
          timeInHours,
          sunrise,
          sunset,
          Offset(size.width * .3, size.height * .2),
          10,
          -.3);
      drawStar(
          canvas,
          timeInHours,
          sunrise,
          sunset,
          Offset(size.width * .38, size.height * .4),
          15,
          -.3);
      drawStar(
          canvas,
          timeInHours,
          sunrise,
          sunset,
          Offset(size.width * .62, size.height * .3),
          20,
          -.3);
      drawStar(
          canvas,
          timeInHours,
          sunrise,
          sunset,
          Offset(size.width * .7, size.height * .2),
          10,
          -.3);
      drawStar(
          canvas,
          timeInHours,
          sunrise,
          sunset,
          Offset(size.width * .8, size.height * .3),
          15,
          -.3);
      drawStar(
          canvas,
          timeInHours,
          sunrise,
          sunset,
          Offset(size.width * .9, size.height * .4),
          20,
          -.3);
    }

    //Draw the sun or moon
    if (isDayTime) {
      drawSun(canvas, sunPosition, sunRadius);
    } else {
      drawMoon(canvas, sunPosition, sunRadius, skyPaint);
    }

    //Let's draw a cloud
    drawCloud(canvas, new Rect.fromLTWH(100, 100, 180, 100));
    drawCloud(canvas, new Rect.fromLTWH(600, 200, 180 * .7, 100 * .7));

    //Draw the cloud base
    drawBackBaseCloud(
        canvas, new Rect.fromLTWH(0, size.height - 150, size.width, 125));
    drawMountain(canvas, new Rect.fromLTWH(0, size.height - 240, 280, 240));
    drawMountain(canvas, new Rect.fromLTWH(600, size.height - 270, 300, 270));
    drawMountain(canvas, new Rect.fromLTWH(300, size.height - 180, 200, 180));
    drawMiddleBaseCloud(
        canvas, new Rect.fromLTWH(0, size.height - 125, size.width, 125));
    drawMountain(canvas, new Rect.fromLTWH(500, size.height - 80, 180, 150));
    drawFrontBaseCloud(
        canvas, new Rect.fromLTWH(0, size.height - 100, size.width, 100));

    //Draw the time
    drawTimeCard(canvas, DateFormat.Hm().format(time));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  Paint getSkyPaint(double time, double sunrise, double sunset, Size size,
      Offset sunPosition) {
    /*We want to transition the sky from day to night, so we'll interpolate the
    colors.  RGB apparently isn't good for interpolating, so we'll switch to HSV.
     */

    var dayTimeInner = HSVColor.fromColor(Color(0xff3ce2f2));
    var dayTimeOuter = HSVColor.fromColor(Color(0xff32c8e9));
    var nightTimeInner = HSVColor.fromColor(Color(0xff0b5379));
    var nightTimeOuter = HSVColor.fromColor(Color(0xff082c46));

    var innerColor = nightTimeInner;
    var outerColor = nightTimeOuter;
    if ((sunrise - time).abs() < 0.5) {
      //30 minutes before and after sunrise
      outerColor =
          HSVColor.lerp(nightTimeOuter, dayTimeOuter, .5 + time - sunrise);
      innerColor =
          HSVColor.lerp(nightTimeInner, dayTimeInner, .5 + time - sunrise);
    } else if ((sunset - time).abs() < 0.5) {
      //30 minutes before and after sunset
      outerColor =
          HSVColor.lerp(dayTimeOuter, nightTimeOuter, .5 + time - sunset);
      innerColor =
          HSVColor.lerp(dayTimeInner, nightTimeInner, .5 + time - sunset);
    } else if (time < sunset && time > sunrise) {
      innerColor = dayTimeInner;
      outerColor = dayTimeOuter;
    }

    var skyGradient = RadialGradient(
      center:
          Alignment(0, -(size.height / 2 - sunPosition.dy) / (size.height / 2)),
      radius: .5,
      colors: [
        innerColor.toColor(),
        outerColor.toColor(),
      ],
      stops: [0, 1.0],
    );

    var skyPaint = Paint();
    Rect skyRect = new Rect.fromLTWH(0, 0, size.width, size.height);
    skyPaint.shader = skyGradient.createShader(skyRect);
    return skyPaint;
  }

  double getSunMoonPosition(
      double time, double sunset, double sunrise, Size size) {
    /*Let's put the sun at about 1/3 down during the daytime, and slowly lower
    when it's close to sunset.
    At sunset, we want the sun fully behind the clouds.
    Then we want to raise the moon to 1/3 from the top.
    When it's close to sunrise, we'll lower the moon, and pull the sun back up.
     */
    double timeForSunMoonToMove = 60; //hour before and after sunrise, sunset
    double timeToSunriseOrSunset =
        60 * Math.min((time - sunset).abs(), (time - sunrise).abs());

    double changeFromTop = (timeForSunMoonToMove -
            Math.min(timeForSunMoonToMove, timeToSunriseOrSunset)) /
        timeForSunMoonToMove;

    double sunMoonPosition =
        ((size.height / 3) + (size.height * (2 / 3) * changeFromTop));

    return sunMoonPosition;
  }
}

void drawSun(Canvas canvas, Offset sunPosition, double sunRadius) {
  //Draw the string
  Paint linePaint = new Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xffffffff)
    ..strokeWidth = 3;
  canvas.drawLine(new Offset(sunPosition.dx, 0), sunPosition, linePaint);

  //Create the paint and draw the circle
  Rect sunRect = new Rect.fromLTWH(sunPosition.dx - sunRadius / 2,
      sunPosition.dy - sunRadius / 2, sunRadius, sunRadius);
  var sunGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [const Color(0xfffef201), const Color(0xffe7ba39)],
  );
  var sunPaint = Paint()..shader = sunGradient.createShader(sunRect);
  canvas.drawCircle(sunPosition, sunRadius, sunPaint);

  //Add the accent
  Paint sunAccent = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xfffef201)
    ..strokeWidth = 1;
  canvas.drawCircle(sunPosition, sunRadius, sunAccent);
}

void drawMoon(
    Canvas canvas, Offset sunPosition, double sunRadius, Paint skyPaint) {
  //Draw the string
  Paint linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xffffffff)
    ..strokeWidth = 3;
  canvas.drawLine(new Offset(sunPosition.dx, 0), sunPosition, linePaint);

  //Create the paint and draw the circle
  Rect sunRect = new Rect.fromLTWH(sunPosition.dx - sunRadius / 2,
      sunPosition.dy - sunRadius / 2, sunRadius, sunRadius);
  var sunGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [const Color(0xffe7ba39), const Color(0xfffef201)],
  );
  var sunPaint = Paint()..shader = sunGradient.createShader(sunRect);
  canvas.drawCircle(sunPosition, sunRadius, sunPaint);

  //Add the accent
  Paint sunAccent = new Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xfffef201)
    ..strokeWidth = 1;
  canvas.drawCircle(sunPosition, sunRadius, sunAccent);

  //Now cut out another circle to make it look like a crescent moon
  double cutoutRadius = sunRadius * .8;
  Offset cutoutPosition = Offset(
      sunPosition.dx + (sunRadius * 1.1 - cutoutRadius) * Math.cos(.5),
      sunPosition.dy + (sunRadius * 1.1 - cutoutRadius) * Math.sin(-.5));
  canvas.drawCircle(cutoutPosition, cutoutRadius, skyPaint);
}

void drawCloud(Canvas canvas, Rect drawRect) {
  //Draw the string
  Paint linePaint = new Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xffffffff)
    ..strokeWidth = 3;
  canvas.drawLine(
      new Offset(drawRect.center.dx, 0), drawRect.center, linePaint);

  //Create the Path.  This is from an SVG drawn with inkscape.
  Path cloudSvgPath = parseSvgPathData(
      "m 0, 0 c -1.31895,-0.069 -5.83115,-0.5554 -10.06568,-0.9024 -60.60234,-5.7618 -120.09399,-49.3566 -156.95521,-114.8182 -2.91558,-5.2758 -7.35836,-13.9532 -9.78801,-19.3678 -2.42965,-5.4146 -4.78988,-9.788 -5.27581,-9.788 -0.41651,0.069 -6.03941,2.2214 -12.42591,4.7205 -20.75613,8.1913 -32.83495,10.2739 -51.09201,8.8855 -29.6417,-2.2908 -55.95131,-11.3152 -81.01138,-27.7674 -22.21392,-14.5084 -42.7618,-35.6117 -56.92317,-58.4504 -6.52534,-10.5516 -13.95312,-26.5872 -18.04881,-39.152 -2.08255,-6.3171 -3.81801,-11.94 -3.81801,-12.5647 0,-1.319 -0.55535,-1.319 -8.74673,0.4165 -24.0188,4.9981 -57.409099,-0.4859 -81.983246,-13.606 -19.576015,-10.4128 -36.652965,-26.3791 -47.968179,-44.9138 -21.58915222,-35.2646 -26.1707728,-82.4692 -12.2176555,-124.1203 13.4671875,-40.0544 43.2477215,-72.334 80.5948715,-87.3979 17.771139,-7.2195 29.294609,-9.3715 48.801199,-9.3715 12.84242,0 15.06382,0.1389 23.11636,1.8743 10.75987,2.2909 24.92124,6.8725 35.95878,11.6623 l 8.2608,3.5404 6.03941,-5.5535 c 20.96439,-19.0207 43.5254,-32.6961 68.09954,-41.1652 16.45219,-5.6229 30.54414,-8.3996 49.35655,-9.6491 40.8875,-2.7768 81.28906,8.5384 120.71877,33.8068 l 5.76173,3.6792 6.73359,-5.97 c 21.03381,-18.6042 47.41284,-30.683 77.54046,-35.4729 10.62103,-1.666 34.1539,-1.666 43.38656,0 32.69611,5.97 60.53293,21.5892 85.87068,47.8988 7.28894,7.636 17.49346,20.409 22.00566,27.6285 l 2.01314,3.1933 11.87056,-5.6923 c 21.31148,-10.274 31.58542,-13.4672 44.98318,-14.0226 39.98506,-1.666 79.69244,19.229 105.72437,55.6737 31.09949,43.5254 41.6511,107.3904 27.35089,165.216 -14.6473,59.2834 -54.07701,103.503 -103.71123,116.276 -4.44279,1.1801 -8.81615,2.0825 -9.71859,2.0825 -0.90244,0 -1.80488,0.2777 -2.01314,0.6248 -0.27767,0.3471 -1.04128,4.1651 -1.80488,8.5385 -15.34149,88.092 -75.24965,158.8989 -150.98522,178.6137 -17.84056,4.6511 -36.58355,6.6642 -49.63423,5.4147 z");

  //Scale the path to the appropriate size.
  Rect svgRect = cloudSvgPath.getBounds();
  final Matrix4 matrix4 = Matrix4.identity();
  matrix4.scale(
      drawRect.width / svgRect.width, -drawRect.height / svgRect.height);
  Path scaledCloudPath = cloudSvgPath.transform(matrix4.storage);

  //Move the cloud path to the right spot
  Rect scaledRect = scaledCloudPath.getBounds();
  Path drawPath = Path();
  drawPath.moveTo(
      drawRect.left - scaledRect.left, drawRect.top - scaledRect.top);
  drawPath.addPath(
      scaledCloudPath,
      new Offset(
          drawRect.left - scaledRect.left, drawRect.top - scaledRect.top));

  //Create the gradient paint
  var cloudGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [const Color(0xffffffff), const Color(0xffd2d2d2)],
  );
  var cloudPaint = Paint()..shader = cloudGradient.createShader(drawRect);

  //Draw the filled in cloud
  canvas.drawShadow(drawPath, Colors.black, 5.0, false);
  canvas.drawPath(drawPath, cloudPaint);

  //Add the accent
  //Draw the string
  Paint cloudAccent = new Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xffffffff)
    ..strokeWidth = 1;
  canvas.drawPath(drawPath, cloudAccent);
}

void drawFrontBaseCloud(Canvas canvas, Rect drawRect) {
  Path frontCloudPath = parseSvgPathData(
      "M 6.3632812 214.52734 C 4.2060018 214.52734 2.0802227 214.65411 -0.015625 214.88477 L -0.015625 301.02539 L 500.04102 301.02539 L 500.04102 214.93164 C 497.85303 214.67432 495.63217 214.52734 493.375 214.52734 C 464.487 214.52734 440.67858 236.20254 437.28125 264.17188 C 432.92392 262.08254 428.06349 260.87891 422.91016 260.87891 C 405.10616 260.87891 390.60434 274.84482 389.65234 292.41016 C 387.27501 291.77416 384.78827 291.40234 382.21094 291.40234 C 375.40827 291.40234 369.16957 293.7736 364.24023 297.71094 C 355.96823 288.59227 344.05877 282.82617 330.77344 282.82617 C 324.03077 282.82617 317.6562 284.34623 311.9082 286.99023 C 303.57087 260.70757 278.98469 241.66211 249.94336 241.66211 C 226.05803 241.66211 205.19124 254.55329 193.89258 273.75195 C 185.74191 265.79862 174.61612 260.87891 162.32812 260.87891 C 153.19746 260.87891 144.71604 263.6091 137.60938 268.25977 C 131.32804 247.00243 111.66895 231.48828 88.376953 231.48828 C 76.13162 231.48828 64.896265 235.78026 56.072266 242.93359 C 46.030933 225.93893 27.535281 214.52734 6.3632812 214.52734 z");
  drawBaseCloud(canvas, drawRect, frontCloudPath);
}

void drawMiddleBaseCloud(Canvas canvas, Rect drawRect) {
  Path middleCloudPath = parseSvgPathData(
      "M 328.43945 217.9082 C 314.29545 217.9082 302.37799 227.35902 298.61133 240.29102 C 288.578 234.13768 274.87772 230.3418 259.76172 230.3418 C 247.33372 230.3418 235.85766 232.90628 226.59766 237.23828 C 220.45766 232.22361 212.62727 229.21289 204.08594 229.21289 C 191.0486 229.21289 179.68652 236.23693 173.47852 246.68359 C 167.51852 238.50493 157.89147 233.16797 146.99414 233.16797 C 142.97681 233.16797 139.14718 233.92333 135.58984 235.25 C 129.71251 227.97267 120.73163 223.31836 110.6543 223.31836 C 96.883631 223.31836 85.174672 232.01903 80.638672 244.20703 C 77.370672 241.45903 73.158068 239.79102 68.552734 239.79102 C 64.286068 239.79102 60.364271 241.23291 57.210938 243.62891 C 49.217604 236.50224 38.712156 232.13477 27.160156 232.13477 C 17.070616 232.13477 7.7673259 235.45623 0.24609375 241.04297 L 0.24609375 299.75391 L 499.75391 299.75391 L 499.75391 238.04102 C 494.03983 235.73528 487.05632 234.36719 479.49023 234.36719 C 468.0449 234.36719 457.91311 237.48463 451.53711 242.2793 C 441.88378 234.80196 429.77443 230.3418 416.62109 230.3418 C 409.43043 230.3418 402.5639 231.67685 396.22656 234.10352 C 391.21056 227.04618 382.98282 222.42578 373.66016 222.42578 C 365.81882 222.42578 358.75094 225.7015 353.71094 230.9375 C 348.0736 223.05617 338.86745 217.9082 328.43945 217.9082 z ");
  drawBaseCloud(canvas, drawRect, middleCloudPath);
}

void drawBackBaseCloud(Canvas canvas, Rect drawRect) {
  Path backCloudPath = parseSvgPathData(
      "M 332.12891 187.44336 C 318.35824 187.44336 306.64928 196.14403 302.11328 208.33203 C 298.84528 205.58403 294.63268 203.91602 290.02734 203.91602 C 285.76068 203.91602 281.84083 205.35791 278.6875 207.75391 C 270.69417 200.62724 260.18677 196.25977 248.63477 196.25977 C 237.56677 196.25977 227.43812 200.24828 219.57812 206.84961 C 217.03013 200.90561 211.12991 196.74219 204.25391 196.74219 C 199.26057 196.74219 194.79295 198.94845 191.73828 202.42578 C 184.32895 199.48578 176.26069 197.85938 167.80469 197.85938 C 149.51269 197.85938 132.99693 205.42336 121.18359 217.58203 C 118.97693 216.3607 116.46168 215.63758 113.79102 215.51758 C 110.65902 203.14158 99.484718 193.97266 86.136719 193.97266 C 78.062052 193.97266 70.785844 197.33928 65.589844 202.72461 C 61.351177 198.85928 55.733542 196.48828 49.546875 196.48828 C 39.734875 196.48828 31.313771 202.41686 27.648438 210.88086 C 23.117771 211.53953 18.971812 213.34815 15.507812 216.02148 C 14.118479 215.67882 12.674354 215.48047 11.179688 215.48047 C 8.3490209 215.48047 5.6828281 216.14983 3.2988281 217.3125 C 2.4466419 215.27001 1.4182103 213.31935 0.24023438 211.47461 L 0.24023438 269.75977 L 499.75977 269.75977 L 499.75977 196.45898 C 493.96519 195.17083 487.73493 194.4668 481.23828 194.4668 C 468.81028 194.4668 457.33422 197.03128 448.07422 201.36328 C 441.93422 196.34861 434.10188 193.33789 425.56055 193.33789 C 412.52321 193.33789 401.16112 200.36193 394.95312 210.80859 C 388.99313 202.62993 379.36608 197.29297 368.46875 197.29297 C 364.45142 197.29297 360.62179 198.04833 357.06445 199.375 C 351.18712 192.09767 342.20624 187.44336 332.12891 187.44336 z ");
  drawBaseCloud(canvas, drawRect, backCloudPath);
}

void drawBaseCloud(Canvas canvas, Rect drawRect, Path path) {
  //Scale the path to the appropriate size.
  Rect svgRect = path.getBounds();
  final Matrix4 matrix4 = Matrix4.identity();
  matrix4.scale(
      drawRect.width / svgRect.width, drawRect.height / svgRect.height);
  Path scaledCloudPath = path.transform(matrix4.storage);

  //Move the cloud path to the right spot
  Rect scaledRect = scaledCloudPath.getBounds();
  Path drawPath = Path();
  drawPath.moveTo(
      drawRect.left - scaledRect.left, drawRect.top - scaledRect.top);
  drawPath.addPath(
      scaledCloudPath,
      new Offset(
          drawRect.left - scaledRect.left, drawRect.top - scaledRect.top));

  //Shadow Path
  Path drawShadowPath = Path();
  drawShadowPath.moveTo(
      drawRect.left - scaledRect.left, drawRect.top - 10 - scaledRect.top);
  drawShadowPath.addPath(
      scaledCloudPath,
      new Offset(
          drawRect.left - scaledRect.left, drawRect.top - 10 - scaledRect.top));

  //Create the gradient paint
  var cloudGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      const Color(0xffd2d2d2),
      const Color(0xffffffff),
      const Color(0xffd2d2d2)
    ],
    stops: [0, 0.5, 1.0],
  );
  var cloudPaint = Paint()..shader = cloudGradient.createShader(drawRect);

  //Draw the filled in cloud
  canvas.drawShadow(drawShadowPath, Colors.black, 10.0, false);
  canvas.drawPath(drawPath, cloudPaint);

  //Add the accent
  Paint cloudAccent = new Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xffffffff)
    ..strokeWidth = 1;
  canvas.drawPath(drawPath, cloudAccent);
}

void drawMountain(Canvas canvas, Rect drawRect) {
  //Create the mountain path
  Path mtnPath = Path();
  mtnPath.moveTo(drawRect.topCenter.dx, drawRect.topCenter.dy);
  mtnPath.lineTo(drawRect.bottomLeft.dx, drawRect.bottomLeft.dy);
  mtnPath.lineTo(drawRect.bottomRight.dx, drawRect.bottomRight.dy);
  mtnPath.close();

  //Create the shadow path
  Path shadowPath = Path();
  shadowPath.moveTo(drawRect.topCenter.dx, drawRect.topCenter.dy);
  shadowPath.addPath(mtnPath, new Offset(0, -10));

  //Create the gradient paint
  var mtnGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      const Color(0xff092d45),
      const Color(0xff082b41),
      const Color(0xff072329),
      const Color(0xff072329)
    ],
    stops: [0, 0.5, 0.5, 1.0],
  );
  var mtnPaint = Paint()..shader = mtnGradient.createShader(drawRect);

  //Draw the mountain
  canvas.drawShadow(shadowPath, Colors.black, 10.0, false);
  canvas.drawPath(mtnPath, mtnPaint);

  //Add some snow
  const snowRatio = 0.3;
  final bezierXOffset = .05 * drawRect.width;
  final bezierYOffset = .025 * drawRect.height;
  Path snowPath = Path();
  snowPath.moveTo(drawRect.topCenter.dx, drawRect.topCenter.dy);
  snowPath.lineTo(
    (drawRect.bottomLeft.dx - drawRect.topCenter.dx) * snowRatio +
        drawRect.topCenter.dx,
    (drawRect.bottomLeft.dy - drawRect.topCenter.dy) * snowRatio +
        drawRect.topCenter.dy,
  );
  snowPath.quadraticBezierTo(
      drawRect.topCenter.dx - bezierXOffset,
      (drawRect.bottomLeft.dy - drawRect.topCenter.dy) * snowRatio +
          drawRect.topCenter.dy +
          bezierYOffset,
      drawRect.topCenter.dx,
      (drawRect.bottomLeft.dy - drawRect.topCenter.dy) * snowRatio +
          drawRect.topCenter.dy -
          bezierYOffset);
  snowPath.quadraticBezierTo(
      drawRect.topCenter.dx + bezierXOffset,
      (drawRect.bottomRight.dy - drawRect.topCenter.dy) * snowRatio +
          drawRect.topCenter.dy +
          bezierYOffset,
      (drawRect.bottomRight.dx - drawRect.topCenter.dx) * snowRatio +
          drawRect.topCenter.dx,
      (drawRect.bottomRight.dy - drawRect.topCenter.dy) * snowRatio +
          drawRect.topCenter.dy);
  snowPath.close();

  var snowGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      const Color(0xffffffff),
      const Color(0xffe7e7e7),
      const Color(0xffb1b1b1),
      const Color(0xffb1b1b1)
    ],
    stops: [0, 0.5, 0.5, 1.0],
  );
  var snowPaint = Paint()..shader = snowGradient.createShader(drawRect);
  canvas.drawPath(snowPath, snowPaint);
}

void drawTimeCard(Canvas canvas, String time) {
  //Draw the string
  Paint linePaint = new Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xffffffff)
    ..strokeWidth = 3;
  canvas.drawLine(new Offset(110, 0), new Offset(110, 20), linePaint);

  //Draw the time
  Paint timePaint = Paint()..color = Colors.grey[50];
  Path timePath = Path();
  timePath.addRRect(
      new RRect.fromLTRBR(20, 20, 180, 84, new ui.Radius.circular(5)));
  canvas.drawShadow(timePath, Colors.black, 10.0, false);
  canvas.drawPath(timePath, timePaint);

  drawText(canvas, time, new Offset(30, 20));

  //Add the accent
  Paint accentPaint = new Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xffffffff)
    ..strokeWidth = 1;
  canvas.drawPath(timePath, accentPaint);
}

void drawText(Canvas canvas, String number, Offset offset) {
  final textStyle = ui.TextStyle(
    color: Colors.black54,
    fontSize: 56,
  );
  final paragraphStyle = ui.ParagraphStyle();
  final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
    ..pushStyle(textStyle)
    ..addText(number);
  final constraints = ui.ParagraphConstraints(width: 300);
  final paragraph = paragraphBuilder.build();
  paragraph.layout(constraints);
  canvas.drawParagraph(paragraph, offset);
}

void drawStar(Canvas canvas, double time, double sunrise, double sunset,
    Offset origin, double starRadius, double rotation) {

  /*
  We only want the stars to appear at night.  They should slowly come down while
  the moon is rising, and raise up again as the moon is lowering.
   */
  Offset starPosition = origin;
  if (sunrise - time < .5 && sunrise - time >= 0){  //Within 30 minutes of sunrise
    starPosition = Offset(origin.dx, origin.dy - (time + .5 - sunrise) * (origin.dy + starRadius) * 2 );
  } else if (time - sunset < .5 && time - sunset >= 0){  //30 minutes after sunset
    starPosition = Offset(origin.dx, origin.dy - (sunset + .5 - time) * (origin.dy + starRadius) * 2 );
  }

  //Draw the string
  Paint linePaint = new Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xffffffff)
    ..strokeWidth = 1;
  canvas.drawLine(new Offset(starPosition.dx, 0), starPosition, linePaint);

  //Create the paint and draw the circle
  Rect starRect = new Rect.fromCenter(
      center: starPosition, width: starRadius * 2, height: starRadius * 2);
  var sunGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [const Color(0xfffef201), const Color(0xffe7ba39)],
  );
  var sunPaint = Paint()..shader = sunGradient.createShader(starRect);

  //Draw the star. 5 points
  double radiansBetweenPoints = Math.pi * 2 / 5.0;
  Path starPath = Path();
  //starPath.moveTo(position.dx + starRadius, position.dy);
  starPath.moveTo(starPosition.dx + starRadius * Math.cos(rotation),
      starPosition.dy + starRadius * Math.sin(rotation));
  for (int i = 0; i < 5; i++) {
    starPath.lineTo(
        starPosition.dx +
            starRadius /
                2 *
                Math.cos((i + .5) * radiansBetweenPoints + rotation),
        starPosition.dy +
            starRadius /
                2 *
                Math.sin((i + .5) * radiansBetweenPoints + rotation));
    starPath.lineTo(
        starPosition.dx +
            starRadius * Math.cos((i + 1) * radiansBetweenPoints + rotation),
        starPosition.dy +
            starRadius * Math.sin((i + 1) * radiansBetweenPoints + rotation));
  }
  starPath.close();
  canvas.drawPath(starPath, sunPaint);

  //Add the accent
  Paint sunAccent = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xfffef201)
    ..strokeWidth = 1;
  canvas.drawPath(starPath, sunAccent);
}

double getSunMoonPosition(
    double time, double sunset, double sunrise, Size size) {
  /*Let's put the sun at about 1/3 down during the daytime, and slowly lower
    when it's close to sunset.
    At sunset, we want the sun fully behind the clouds.
    Then we want to raise the moon to 1/3 from the top.
    When it's close to sunrise, we'll lower the moon, and pull the sun back up.
     */
  double timeForSunMoonToMove = 60; //hour before and after sunrise, sunset
  double timeToSunriseOrSunset =
      60 * Math.min((time - sunset).abs(), (time - sunrise).abs());

  double changeFromTop = (timeForSunMoonToMove -
      Math.min(timeForSunMoonToMove, timeToSunriseOrSunset)) /
      timeForSunMoonToMove;

  double sunMoonPosition =
  ((size.height / 3) + (size.height * (2 / 3) * changeFromTop));

  return sunMoonPosition;
}
