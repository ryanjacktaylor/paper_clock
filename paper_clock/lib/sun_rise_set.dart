import 'dart:math' as Math;

class SunRiseSetAlgo
{
  static double calcSunrise(int dayOfYear, double localOffset, double latitude, double longitude)
  {
    return calc(dayOfYear, localOffset, latitude, longitude, true);
  }
  static double calcSunset(int dayOfYear, double localOffset, double latitude, double longitude)
  {
    return calc(dayOfYear, localOffset, latitude, longitude, false);
  }

  static double calc(int dayOfYear, double localOffset, double latitude, double longitude, bool rise)
  {
    //1. first calculate the day of the year

    //        int N1 = floor(275 * month / 9.0);
    //        int N2 = floor((month + 9) / 12.0);
    //        int N3 = (1 + floor((year - 4 * floor(year / 4.0) + 2) / 3.0));
    //        int N = N1 - (N2 * N3) + day - 30;
    int N = dayOfYear;

    //2. convert the longitude to hour value and calculate an approximate time
    double lngHour = longitude / 15;
    double t = rise?
    N + (( 6 - lngHour) / 24) :
    N + ((18 - lngHour) / 24);

    //3. calculate the Sun's mean anomaly
    double M = (0.9856 * t) - 3.289;

    //4. calculate the Sun's true longitude
    double L = M + (1.916 * sinDeg(M)) + (0.020 * sinDeg(2 * M)) + 282.634;
    L = mod(L, 360);

    //5a. calculate the Sun's right ascension
    double rightAscension = atanDeg(0.91764 * tanDeg(L));
    rightAscension = mod(rightAscension, 360);

    //5b. right ascension value needs to be in the same quadrant as L
    double lQuadrant  = (( L/90).floorToDouble()) * 90;
    double raQuadrant = ((rightAscension/90).floorToDouble()) * 90;
    rightAscension = rightAscension + (lQuadrant - raQuadrant);

    //5c. right ascension value needs to be converted into hours
    rightAscension = rightAscension / 15;

    //6. calculate the Sun's declination
    double sinDec = 0.39782 * sinDeg(L);
    double cosDec = cosDeg(asinDeg(sinDec));

    //7a. calculate the Sun's local hour angle
    double zenith = 90 + 50.0/60;
    double cosH = (cosDeg(zenith) - (sinDec * sinDeg(latitude))) / (cosDec * cosDeg(latitude));

    /*
    if (cosH >  1)
      throw new Error("the sun never rises on this location (on the specified date");
    if (cosH < -1)
      throw new Error("the sun never sets on this location (on the specified date");
     */
    //TODO: Figure out what to do in those weird places that don't have a daily sunrise/set

    //7b. finish calculating H and convert into hours
    double H = rise?
    360 - acosDeg(cosH) :
    acosDeg(cosH);
    H = H / 15;

    //8. calculate local mean time of rising/setting
    double T = H + rightAscension - (0.06571 * t) - 6.622;

    //9. adjust back to UTC
    double utc = T - lngHour;

    //10. convert UT value to local time zone of latitude/longitude
    double localT = utc + localOffset;
    localT = mod(localT, 24);
    return localT;
  }

  static double sinDeg(double degree)
  {
    return Math.sin(degree*Math.pi/180);
  }
  static double cosDeg(double degree)
  {
    return Math.cos(degree*Math.pi/180);
  }
  static double tanDeg(double degree)
  {
    return Math.tan(degree*Math.pi/180);
  }
  static double atanDeg(double x)
  {
    return Math.atan(x) *180/Math.pi;
  }
  static double asinDeg(double x)
  {
    return Math.asin(x) *180/Math.pi;
  }
  static double acosDeg(double x)
  {
    return Math.acos(x) *180/Math.pi;
  }

  static double mod(double x, double lim)
  {
    return x - lim * (x/lim).floorToDouble();
  }

}