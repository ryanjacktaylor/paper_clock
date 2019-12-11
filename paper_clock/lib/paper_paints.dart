import 'package:flutter/material.dart';
import 'package:paper_clock/paper_colors.dart';

class PaperPaints {
  static Paint getLinePaint(double strokeWidth) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = strokeWidth;
  }

  static Paint getSkyPaint(double time, double sunrise, double sunset,
      Size size, Offset sunPosition) {
    /*We want to transition the sky from day to night, so we'll interpolate the
    colors.  RGB apparently isn't good for interpolating, so we'll switch to HSV.
     */

    var dayTimeInner = HSVColor.fromColor(PaperColors.DAYTIME_LIGHT);
    var dayTimeOuter = HSVColor.fromColor(PaperColors.DAYTIME_DARK);
    var nightTimeInner = HSVColor.fromColor(PaperColors.NIGHT_LIGHT);
    var nightTimeOuter = HSVColor.fromColor(PaperColors.NIGHT_DARK);

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

  static Paint getSunAndStarPaint(Offset position, double radius) {
    Rect rect = new Rect.fromLTWH(
        position.dx - radius / 2, position.dy - radius / 2, radius, radius);
    var gradient = LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [PaperColors.SUN_STAR_LIGHT, PaperColors.SUN_STAR_DARK],
    );
    return Paint()..shader = gradient.createShader(rect);
  }

  static Paint getSunMoonStarAccentPaint() {
    return Paint()
      ..style = PaintingStyle.stroke
      ..color = PaperColors.SUN_STAR_LIGHT
      ..strokeWidth = 1;
  }

  static Paint getMoonPaint(Offset position, double radius) {
    Rect rect = new Rect.fromLTWH(
        position.dx - radius / 2, position.dy - radius / 2, radius, radius);
    var gradient = LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [PaperColors.SUN_STAR_DARK, PaperColors.SUN_STAR_LIGHT],
    );
    return Paint()..shader = gradient.createShader(rect);
  }

  static Paint getShadowPaint(double strokeWidth) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black12
      ..strokeWidth = strokeWidth;
  }

  static Paint getLightningPaint(Rect rect) {
    LinearGradient gradient = LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [PaperColors.SUN_STAR_LIGHT, PaperColors.SUN_STAR_DARK],
    );
    return Paint()..shader = gradient.createShader(rect);
  }

  static Paint getCloudPaint(Rect rect, bool isDark){
    var cloudGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, Colors.grey[350]],
    );
    if (isDark) {
      cloudGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.grey[350], Colors.grey[400]],
      );
    }
    return Paint()..shader = cloudGradient.createShader(rect);
  }

  static Paint getBaseCloudPaint(Rect rect){
    var cloudGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.grey[350],
        Colors.white,
        Colors.grey[350]
      ],
      stops: [0, 0.5, 1.0],
    );
    return Paint()..shader = cloudGradient.createShader(rect);
  }

  static Paint getMountainPaint(Rect rect){
    var mtnGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        PaperColors.MTN_LIGHT,
        PaperColors.MTN_MID,
        PaperColors.MTN_DARK,
        PaperColors.MTN_DARK,
      ],
      stops: [0, 0.5, 0.5, 1.0],
    );
    return Paint()..shader = mtnGradient.createShader(rect);
  }

  static Paint getMountainSnowPaint(Rect rect){
    var snowGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white,
        Colors.grey[300],
        PaperColors.SNOW_GREY,
        PaperColors.SNOW_GREY
      ],
      stops: [0, 0.5, 0.5, 1.0],
    );
    return Paint()..shader = snowGradient.createShader(rect);
  }

  static Paint getRainPaint(){
    return Paint()
      ..style = PaintingStyle.fill
      ..color = PaperColors.RAIN;
  }

  static Paint getCardPaint(){
    return Paint()..color = Colors.white;
  }
}
