import 'dart:ui' as ui;
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:paper_clock/paper_clouds.dart';
import 'package:paper_clock/paper_paints.dart';
import 'package:intl/intl.dart';

class PaperCanvas extends CustomPainter {
  final DateTime _time;
  final _sunrise;
  final _sunset;
  final _weatherCondition;
  final _temperatureInC;
  final _is24Hour;
  final _temperatureString;

  PaperCanvas(this._time, this._sunrise, this._sunset, this._weatherCondition,
      this._temperatureInC, this._is24Hour, this._temperatureString);

  @override
  void paint(Canvas canvas, Size size) {
    /*Get the time in hours (decimal) and calculate where the sun should be.
    We want the sun to go down at sunset and up at sunrise, with a similar setup
    for the moon.
     */
    double timeInHours =
        _time.hour + _time.minute / 60.0 + _time.second / 3600.0;
    final Offset sunMoonPosition = Offset(size.width / 2,
        getSunMoonPosition(timeInHours, _sunset, _sunrise, size));

    //Check if it's day or night
    bool isDayTime = timeInHours > _sunrise && timeInHours < _sunset;

    //Draw the sky background
    Paint skyPaint = PaperPaints.getSkyPaint(
        timeInHours, _sunrise, _sunset, size, sunMoonPosition);
    Rect skyRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(skyRect); //Prevents overflow beyond border
    canvas.drawRect(skyRect, skyPaint);

    //Draw the stars
    double smallStarSize = size.width * .01;
    double medStarSize = size.width * .015;
    double largeStarSize = size.width * .02;
    if (!isDayTime) {
      drawStar(canvas, timeInHours, _sunrise, _sunset,
          Offset(size.width * .08, size.height * .6), medStarSize, -.1);
      drawStar(canvas, timeInHours, _sunrise, _sunset,
          Offset(size.width * .2, size.height * .5), medStarSize, .2);
      drawStar(canvas, timeInHours, _sunrise, _sunset,
          Offset(size.width * .3, size.height * .2), smallStarSize, -.2);
      drawStar(canvas, timeInHours, _sunrise, _sunset,
          Offset(size.width * .35, size.height * .38), medStarSize, .1);
      drawStar(canvas, timeInHours, _sunrise, _sunset,
          Offset(size.width * .62, size.height * .25), largeStarSize, .2);
      drawStar(canvas, timeInHours, _sunrise, _sunset,
          Offset(size.width * .7, size.height * .2), smallStarSize, -.3);
      drawStar(canvas, timeInHours, _sunrise, _sunset,
          Offset(size.width * .8, size.height * .3), medStarSize, -.1);
      drawStar(canvas, timeInHours, _sunrise, _sunset,
          Offset(size.width * .9, size.height * .4), largeStarSize, .3);
    }

    //Draw the sun or moon
    final double sunMoonRadius = 0.13 * size.height;
    if (isDayTime) {
      drawSun(canvas, sunMoonPosition, sunMoonRadius);
    } else {
      drawMoon(canvas, sunMoonPosition, sunMoonRadius, skyPaint);
    }

    //Draw some clouds based on the weather
    Size normalCloudSize = Size(size.width * .2, size.height * .2);
    List<Rect> cloudRects = [
      Rect.fromLTWH(size.width * .23, size.width * .27,
          normalCloudSize.width * .7, normalCloudSize.height * .7),
      Rect.fromLTWH(size.width * .66, size.width * .20,
          normalCloudSize.width * .7, normalCloudSize.height * .7)
    ];
    for (Rect cloudRect in cloudRects) {
      drawCloud(canvas, cloudRect, _weatherCondition, _temperatureInC);
    }
    if (_weatherCondition == WeatherCondition.cloudy ||
        _weatherCondition == WeatherCondition.rainy ||
        _weatherCondition == WeatherCondition.snowy ||
        _weatherCondition == WeatherCondition.thunderstorm ||
        _weatherCondition == WeatherCondition.foggy) {
      //Put up a large cloud over the sun/moon
      drawCloud(
          canvas,
          Rect.fromLTWH(
              sunMoonPosition.dx - (normalCloudSize.width * 1.3) / 2,
              sunMoonPosition.dy - sunMoonRadius * .9,
              normalCloudSize.width * 1.3,
              normalCloudSize.height * 1.3),
          _weatherCondition,
          _temperatureInC);
    }

    //Draw the cloud base and mountains
    drawBackBaseCloud(canvas,
        Rect.fromLTWH(0, size.height * .71, size.width, size.height * .24));
    drawMountain(
        canvas,
        Rect.fromLTWH(
            0, size.height * .54, size.width * .32, size.height * .46));
    drawMountain(
        canvas,
        Rect.fromLTWH(size.width * .66, size.height * .48, size.width * .33,
            size.height * .52));
    drawMountain(
        canvas,
        Rect.fromLTWH(size.width * .33, size.height * .66, size.width * .22,
            size.height * .34));
    drawMiddleBaseCloud(canvas,
        Rect.fromLTWH(0, size.height * .76, size.width, size.height * .24));
    drawMountain(
        canvas,
        Rect.fromLTWH(size.width * .55, size.height * .85, size.width * .2,
            size.height * .27));
    drawFrontBaseCloud(canvas,
        Rect.fromLTWH(0, size.height * .81, size.width, size.height * .19));

    //Draw the time
    Size timeCardSize = Size(160, 64);
    Offset timeCardOffset = Offset(size.width * .02, size.width * .02);
    drawTimeCard(
        canvas,
        RRect.fromLTRBR(
            timeCardOffset.dx,
            timeCardOffset.dy,
            timeCardSize.width + timeCardOffset.dx,
            timeCardSize.height + timeCardOffset.dy,
            ui.Radius.circular(5)),
        _time,
        _is24Hour);

    //Draw the temperature
    Size tempCardSize = Size(timeCardSize.width / 2, timeCardSize.height / 2);
    Offset tempCardOffset = Offset(
        timeCardOffset.dx + (timeCardSize.width - tempCardSize.width) / 2,
        timeCardOffset.dy + timeCardSize.height);
    drawTempCard(
        canvas,
        RRect.fromLTRBR(
            tempCardOffset.dx,
            tempCardOffset.dy + tempCardSize.height * .2,
            tempCardSize.width + tempCardOffset.dx,
            tempCardSize.height + tempCardOffset.dy + tempCardSize.height * .2,
            ui.Radius.circular(3)),
        _temperatureString,
        tempCardSize.height * .2);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
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
  canvas.drawLine(Offset(sunPosition.dx, 0), sunPosition,
      PaperPaints.getLinePaint(Math.max(2, .03 * sunRadius)));

  //Create the paint and draw the circle
  canvas.drawCircle(sunPosition, sunRadius,
      PaperPaints.getSunAndStarPaint(sunPosition, sunRadius));

  //Add the accent
  canvas.drawCircle(
      sunPosition, sunRadius, PaperPaints.getSunMoonStarAccentPaint());
}

void drawMoon(
    Canvas canvas, Offset position, double moonRadius, Paint skyPaint) {
  //Draw the string
  canvas.drawLine(Offset(position.dx, 0), position,
      PaperPaints.getLinePaint(Math.max(2, .03 * moonRadius)));

  //Create the paint and draw the circle
  canvas.drawCircle(
      position, moonRadius, PaperPaints.getMoonPaint(position, moonRadius));

  //Add the accent
  canvas.drawCircle(
      position, moonRadius, PaperPaints.getSunMoonStarAccentPaint());

  //Now cut out another circle to make it look like a crescent moon
  double cutoutRadius = moonRadius * .8;
  Offset cutoutPosition = Offset(
      position.dx + (moonRadius * 1.1 - cutoutRadius) * Math.cos(.5),
      position.dy + (moonRadius * 1.1 - cutoutRadius) * Math.sin(-.5));
  canvas.drawCircle(cutoutPosition, cutoutRadius, skyPaint);
}

void drawCloud(Canvas canvas, Rect drawRect, WeatherCondition weatherCondition,
    double tempInC) {
  //Draw the string
  canvas.drawLine(Offset(drawRect.center.dx, 0), drawRect.center,
      PaperPaints.getLinePaint(Math.max(1, .003 * drawRect.width * .2)));

  //Is it raining?  We'll assume that if there is a thunderstorm
  //and it's above freezing, it's probably raining.
  if ((weatherCondition == WeatherCondition.thunderstorm && (tempInC >= 0)) ||
      weatherCondition == WeatherCondition.rainy) {
    drawRain(canvas, drawRect);
  }

  //Snowy?  Cool!  Let's draw snowflakes.  And if it's below freezing and a
  //thunderstorm, let's assume it's also snowing.
  if ((weatherCondition == WeatherCondition.thunderstorm && (tempInC < 0)) ||
      weatherCondition == WeatherCondition.snowy) {
    drawSnow(canvas, drawRect);
  }

  //If there's a thunderstorm, let's draw a lightning bolt
  if (weatherCondition == WeatherCondition.thunderstorm) {
    drawLightning(canvas, drawRect);
  }

  //Create the gradient paint.  If rainy, snowy, thunderstormy, make the cloud darker
  Paint cloudPaint = PaperPaints.getCloudPaint(
      drawRect,
      weatherCondition == WeatherCondition.thunderstorm ||
          weatherCondition == WeatherCondition.rainy);

  //Draw the filled in cloud
  Path cloudPath = PaperClouds.getScaledCloudPath(drawRect);
  canvas.drawShadow(cloudPath, Colors.black, 5.0, false);
  canvas.drawPath(cloudPath, cloudPaint);

  //Add the accent if no rain, snow, or thunderstorms
  if (weatherCondition != WeatherCondition.thunderstorm &&
      weatherCondition != WeatherCondition.rainy) {
    canvas.drawPath(cloudPath, PaperPaints.getLinePaint(1));
  }
}

void drawFrontBaseCloud(Canvas canvas, Rect drawRect) {
  //Get the cloud paths.  The shadow path is offset vertically
  Map<String, Path> cloudPaths =
      PaperClouds.getScaledFrontBaseClouds(drawRect, drawRect.height * .08);

  //Draw the filled in cloud.  The shadow is drawn on a vertically offset path.
  canvas.drawShadow(cloudPaths[PaperClouds.SHADOW_PATH], Colors.black, 10.0, false);
  canvas.drawPath(cloudPaths[PaperClouds.CLOUD_PATH], PaperPaints.getBaseCloudPaint(drawRect));

  //Add the accent
  canvas.drawPath(cloudPaths[PaperClouds.CLOUD_PATH], PaperPaints.getLinePaint(1));
}

void drawMiddleBaseCloud(Canvas canvas, Rect drawRect) {
  //Get the cloud paths.  The shadow path is offset vertically
  Map<String, Path> cloudPaths =
      PaperClouds.getScaledMiddleBaseClouds(drawRect, drawRect.height * .08);

  //Draw the filled in cloud.  The shadow is drawn on a vertically offset path.
  canvas.drawShadow(cloudPaths[PaperClouds.SHADOW_PATH], Colors.black, 10.0, false);
  canvas.drawPath(cloudPaths[PaperClouds.CLOUD_PATH], PaperPaints.getBaseCloudPaint(drawRect));

  //Add the accent
  canvas.drawPath(cloudPaths[PaperClouds.CLOUD_PATH], PaperPaints.getLinePaint(1));
}

void drawBackBaseCloud(Canvas canvas, Rect drawRect) {
  //Get the cloud paths.  The shadow path is offset vertically
  Map<String, Path> cloudPaths =
      PaperClouds.getScaledBackBaseClouds(drawRect, drawRect.height * .08);

  //Draw the filled in cloud.  The shadow is drawn on a vertically offset path.
  canvas.drawShadow(cloudPaths[PaperClouds.SHADOW_PATH], Colors.black, 10.0, false);
  canvas.drawPath(cloudPaths[PaperClouds.CLOUD_PATH], PaperPaints.getBaseCloudPaint(drawRect));

  //Add the accent
  canvas.drawPath(cloudPaths[PaperClouds.CLOUD_PATH], PaperPaints.getLinePaint(1));
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

  //Draw the mountain
  canvas.drawShadow(shadowPath, Colors.black, 10.0, false);
  canvas.drawPath(mtnPath, PaperPaints.getMountainPaint(drawRect));

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

  //Draw the snow
  canvas.drawPath(snowPath, PaperPaints.getMountainSnowPaint(drawRect));
}

void drawTimeCard(Canvas canvas, RRect rect, DateTime time, bool _is24Hour) {
  //Draw the string
  Paint linePaint = PaperPaints.getLinePaint(2);
  canvas.drawLine(Offset(rect.width * .1 + rect.left, 0),
      Offset(rect.width * .1 + rect.left, rect.top), linePaint);
  canvas.drawLine(Offset(rect.width * .9 + rect.left, 0),
      Offset(rect.width * .9 + rect.left, rect.top), linePaint);

  //Draw the time card
  Path timePath = Path();
  timePath.addRRect(rect);
  canvas.drawShadow(timePath, Colors.black, 10.0, false);
  canvas.drawPath(timePath, PaperPaints.getCardPaint());

  //Create the time string
  String timeString = DateFormat.Hm().format(time);
  if (!_is24Hour && time.hour >= 13) {
    timeString = DateFormat.Hm().format(time.subtract(Duration(hours: 12)));
  }
  //Remove the leading 0
  if (timeString[0] == "0") timeString = timeString.substring(1);

  drawText(
      canvas,
      timeString,
      Rect.fromCenter(
          center: rect.center, width: rect.width, height: rect.height));
}

void drawTempCard(
    Canvas canvas, RRect rect, String tempString, double lineLength) {
  //Draw the string
  Paint linePaint = PaperPaints.getLinePaint(1);
  canvas.drawLine(Offset(rect.width * .1 + rect.left, rect.top - lineLength),
      Offset(rect.width * .1 + rect.left, rect.top), linePaint);
  canvas.drawLine(Offset(rect.width * .9 + rect.left, rect.top - lineLength),
      Offset(rect.width * .9 + rect.left, rect.top), linePaint);

  //Draw the time card
  Path tempPath = Path();
  tempPath.addRRect(rect);
  canvas.drawShadow(tempPath, Colors.black, 10.0, false);
  canvas.drawPath(tempPath, PaperPaints.getCardPaint());

  drawText(
      canvas,
      tempString,
      Rect.fromCenter(
          center: rect.center, width: rect.width, height: rect.height));
}

void drawText(Canvas canvas, String number, Rect rect) {
  final textStyle = ui.TextStyle(
    color: Colors.black87,
    fontSize: rect.height * 0.875,
  );
  final paragraphStyle =
      ui.ParagraphStyle(textAlign: TextAlign.center, maxLines: 1);
  final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
    ..pushStyle(textStyle)
    ..addText(number);
  final constraints = ui.ParagraphConstraints(width: rect.width);
  final paragraph = paragraphBuilder.build();
  paragraph.layout(constraints);
  canvas.drawParagraph(paragraph, rect.topLeft);
}

void drawStar(Canvas canvas, double time, double sunrise, double sunset,
    Offset origin, double starRadius, double rotation) {
  /*
  We only want the stars to appear at night.  They should slowly come down while
  the moon is rising, and raise up again as the moon is lowering.
   */
  Offset starPosition = origin;
  if (sunrise - time < .5 && sunrise - time >= 0) {
    //Within 30 minutes of sunrise
    starPosition = Offset(origin.dx,
        origin.dy - (time + .5 - sunrise) * (origin.dy + starRadius) * 2);
  } else if (time - sunset < .5 && time - sunset >= 0) {
    //30 minutes after sunset
    starPosition = Offset(origin.dx,
        origin.dy - (sunset + .5 - time) * (origin.dy + starRadius) * 2);
  }

  //Draw the string
  canvas.drawLine(
      Offset(starPosition.dx, 0), starPosition, PaperPaints.getLinePaint(1));

  //Draw the star. 5 points
  double radiansBetweenPoints = Math.pi * 2 / 5.0;
  Path starPath = Path();
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
  canvas.drawShadow(starPath, Colors.black, 5, false);
  canvas.drawPath(
      starPath, PaperPaints.getSunAndStarPaint(starPosition, starRadius));

  //Add the accent
  canvas.drawPath(starPath, PaperPaints.getSunMoonStarAccentPaint());
}

void drawRain(Canvas canvas, Rect drawRect){
  for (int col = 0; col < 6; col++) {
    for (int row = 0; row < 2; row++) {
      if (row == 1 && (col == 7)) continue;
      //Create the raindrop path
      Path rainDropPath = Path();
      rainDropPath.moveTo(
          drawRect.left + drawRect.width * (.143 * col + row * .0715 + .143),
          drawRect.bottom + row * drawRect.height * .3);
      rainDropPath.relativeLineTo(0, drawRect.width * .1);
      rainDropPath.relativeArcToPoint(
          Offset(drawRect.width * .06, -drawRect.width * .02),
          radius: Radius.circular(drawRect.width * .03),
          clockwise: false);
      rainDropPath.relativeLineTo(
          -drawRect.width * .03, -drawRect.width * .04);

      //Create the paint
      canvas.drawShadow(rainDropPath, Colors.black, 3.0, true);
      canvas.drawPath(rainDropPath, PaperPaints.getRainPaint());
    }
  }
}

void drawSnow(Canvas canvas, Rect drawRect){
  for (int col = 1; col < 6; col++) {
    for (int row = 0; row < 2; row++) {
      if (row == 1 && col == 5) continue;
      //Create the raindrop path
      Path snowPath = Path();
      const numberOfPoints = 6;
      double radToPoint = Math.pi * 2 / numberOfPoints;
      for (int i = 0; i < numberOfPoints; i++) {
        snowPath.moveTo(
            drawRect.left + drawRect.width * (.167 * col + row * .083),
            drawRect.bottom +
                row * drawRect.height * .25 +
                drawRect.height * .125);
        snowPath.relativeLineTo(
            drawRect.width * .06 * Math.cos(radToPoint * i),
            drawRect.width * .06 * Math.sin(radToPoint * i));
      }

      //Shadow Path
      Path shadowPath = Path();
      shadowPath.moveTo(
          drawRect.left + drawRect.width * (.167 * col + row * .083),
          drawRect.bottom +
              2 +
              row * drawRect.height * .25 +
              drawRect.height * .125);
      shadowPath.addPath(snowPath, Offset(1, 2));

      //Draw the snow
      canvas.drawPath(
          shadowPath, PaperPaints.getShadowPaint(.03 * drawRect.width));
      canvas.drawLine(
          Offset(drawRect.left + drawRect.width * (.167 * col + row * .083),
              drawRect.bottom - drawRect.height * .1),
          Offset(
              drawRect.left + drawRect.width * (.167 * col + row * .083),
              drawRect.bottom +
                  row * drawRect.height * .25 +
                  drawRect.height * .125),
          PaperPaints.getLinePaint(0.5));
      canvas.drawPath(
          snowPath, PaperPaints.getLinePaint(.025 * drawRect.width));
    }
  }
}

void drawLightning(Canvas canvas, Rect drawRect){
  Path lightningPath = Path();
  lightningPath.moveTo(
      drawRect.center.dx, drawRect.bottomCenter.dy - .2 * drawRect.height);
  lightningPath.relativeLineTo(-drawRect.width * .12, drawRect.height * .45);
  lightningPath.relativeLineTo(drawRect.width * .13, 0);
  lightningPath.relativeLineTo(-drawRect.width * .12, drawRect.height * .45);
  lightningPath.relativeLineTo(drawRect.width * .22, -drawRect.height * .55);
  lightningPath.relativeLineTo(-drawRect.width * .11, 0);
  lightningPath.relativeLineTo(drawRect.width * .22, -drawRect.height * .55);

  lightningPath.close();

  //Draw the shadow and lightning
  canvas.drawShadow(lightningPath, Colors.black, 5.0, true);
  canvas.drawPath(lightningPath,
      PaperPaints.getLightningPaint(lightningPath.getBounds()));
}
