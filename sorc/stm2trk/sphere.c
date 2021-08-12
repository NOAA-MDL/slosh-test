/*****************************************************************************
 * sphere.c
 *
 * DESCRIPTION:
 *    This module contains computations that deal with distances or angles on
 * a sphere.
 *
 * HISTORY
 *  10/2003 Arthur Taylor RSIS/MDL: Created
 *
 * NOTES
 *   Originally a lot of this was in mercator.c.  The original procedures
 * assumed: 60nm = 1 degree => 2 pi R = 360 * 60 nm => R = 6366.7070 km
 ****************************************************************************/
#include <math.h>
#include "sphere.h"

#define PI_360 0.008726646259972
#ifndef PI_180
#define PI_180 0.01745329251994
#endif
#define C180_PI 57.29577951308
#define PI 3.14159265359

/*****************************************************************************
 * BearCompute() --
 *
 * Arthur Taylor / TDL
 *
 * PURPOSE
 *    To compute the bearing from one lat/lon to another in degrees from
 * north, treating the surface as a sphere, rather than as a plane.  Hence
 * no map projection.
 *
 * ARGUMENTS
 * f_radian = Return the answer in radians (Input)
 *     lat1 = The (unprojected) latitude of point 1 (degrees) (Input)
 *     lon1 = The (unprojected) longitude of point 1 (neg west degrees) (In)
 *     lat2 = The (unprojected) latitude of point 2 (degrees) (Input)
 *     lon2 = The (unprojected) longitude of point 2 (neg west degrees) (In)
 *    theta = The direction from point 1 to point 2 (in degrees from N) (Out)
 *
 * FILES/DATABASES: None
 *
 * RETURNS: void
 *
 * HISTORY
 *   6/1998 Arthur Taylor (RDC/TDL): Created (originally in mercator.c)
 *  10/2003 AAT (RSIS/MDL): Revisited.
 *
 * NOTES
 ****************************************************************************/
void BearCompute (int f_radian, double lat1, double lon1, double lat2,
                  double lon2, double *theta)
{
   lat1 = lat1 * PI_180;
   lon1 = lon1 * PI_180;
   lat2 = lat2 * PI_180;
   lon2 = lon2 * PI_180;
   *theta = PI + atan2 (cos (lat2) *
                        (cos (lon2) * sin (lon1) - sin (lon2) * cos (lon1)),
                        sin (lat1) * cos (lat2) * cos (lon1 - lon2) -
                        cos (lat1) * sin (lat2));
   if (*theta > 2 * PI)
      *theta = *theta - 2 * PI;
   if (!f_radian) {
      *theta = *theta * C180_PI;
   }
}

/*****************************************************************************
 * DistCompute() --
 *
 * Arthur Taylor / TDL
 *
 * PURPOSE
 *    To compute the distance between two lat/lon points, assuming a spherical
 * earth.
 *
 * ARGUMENTS
 *    R = Radius of earth to use (km) (6371.2 : GRIB2) (6367.47 : GRIB1)
 *        (60nm = 1 degree => 2 pi R = 360 * 60 nm => R = 6366.7070 km)
 * unit = Return distance in: 0 (nautical miles), 1 (statute miles), 2 km
 * lat1 = The (unprojected) latitude of point 1 (degrees) (Input)
 * lon1 = The (unprojected) longitude of point 1 (neg west degrees) (In)
 * lat2 = The (unprojected) latitude of point 2 (degrees) (Input)
 * lon2 = The (unprojected) longitude of point 2 (neg west degrees) (In)
 * dist = The distance from point 1 to point 2 (Output)
 *
 * FILES/DATABASES: None
 *
 * RETURNS: (int) -1 if unit is not valid.
 *
 * HISTORY
 *   6/1998 Arthur Taylor (RDC/TDL): Created
 *  10/2003 AAT (RSIS/MDL): Allowed Radius of earth to be passed in.
 *
 * NOTES
 *   Algortihm see:
 * Haversine Formula (from R.W. Sinnott, "Virtues of the Haversine",
 * Sky and Telescope, vol. 68, no. 2, 1984, p. 159):
 *    dlon = lon2 - lon1
 *    dlat = lat2 - lat1
 *    a = (sin(dlat/2))^2 + cos(lat1) * cos(lat2) * (sin(dlon/2))^2
 *    c = 2 * atan2(sqrt(a), sqrt(1-a))
 *--- c = 2 * arcsin(min(1,sqrt(a)))
 *    R = Radius of earth
 *    d = R * c
 ****************************************************************************/
int DistCompute (double R, int unit, double lat1, double lon1, double lat2,
                 double lon2, double *dist)
{
   enum { NM, SM, KM };
   double del_lat, del_lon;
   double a, c;

   del_lon = (lon2 - lon1) * PI_360;
   del_lat = (lat2 - lat1) * PI_360;

   a = sin (del_lat) * sin (del_lat) +
      cos (lat1 * PI_180) * cos (lat2 * PI_180) *
      sin (del_lon) * sin (del_lon);
/*
   c = 2 * atan2 (sqrt(a), sqrt(1 - a));
*/
   if (sqrt (a) < 1) {
      c = 2 * asin (sqrt (a));
   } else {
      c = 2 * asin (1);
   }
   switch (unit) {
      case NM:
         /* *dist = 60. * C180_PI * c; */
         *dist = (R * c) / 1.852;
         return 0;
      case SM:
         *dist = ((R * c) / 1.852) * 1.151;
         return 0;
      case KM:
         *dist = R * c;
         return 0;
      default:
         /* unrecognized unit. */
         return -1;
   }
}

/*****************************************************************************
 * LatLonCompute() --
 *
 * Arthur Taylor / TDL
 *
 * PURPOSE
 *    Given a lat/lon and a distance and bearing on a sphere, compute the
 * resulting lat/lon.
 *
 * ARGUMENTS
 *    R = Radius of earth to use (km) (6371.2 : GRIB2) (6367.47 : GRIB1)
 *        (60nm = 1 degree => 2 pi R = 360 * 60 nm => R = 6366.7070 km)
 * unit = "dist" is in: 0 (nautical miles), 1 (statute miles), 2 km
 * lat1 = The (unprojected) latitude of point 1 (degrees) (Input)
 * lon1 = The (unprojected) longitude of point 1 (neg west degrees) (In)
 * dist = The distance to travel on the sphere. (Input)
 * bear = The direction from point 1 to travel (in degrees from N) (Input)
 * lat2 = The (unprojected) latitude of point 2 (degrees) (Output)
 * lon2 = The (unprojected) longitude of point 2 (neg west degrees) (Out)
 *
 * FILES/DATABASES: None
 *
 * RETURNS: (int) -1 if unit is not valid.
 *
 * HISTORY
 *  10/2003 Arthur Taylor (RSIS/MDL): Created
 *
 * NOTES
 ****************************************************************************/
int LatLonCompute (double R, int unit, double lat1, double lon1, double dist,
                   double bear, double *lat2, double *lon2)
{
   enum { NM, SM, KM };
   double A, B, C;

   lat1 = lat1 * PI_180;
   lon1 = lon1 * PI_180;
   /* need dist in km since R is in km. */
   switch (unit) {
      case NM:
         /* convert from nm to km */
         dist = (dist * 1.852) / R;
         break;
      case SM:
         /* convert from sm to km */
         dist = (dist * 1.852) / (1.151 * R);
         break;
      case KM:
         dist = dist / R;
         break;
      default:
         /* unrecognized unit. */
         return -1;
   }
   /* (PI - bear) is to get bear oriented correctly. */
   bear = PI - bear * PI_180;

   *lat2 = asin (cos (dist) * sin (lat1) -
                 sin (dist) * cos (bear) * cos (lat1)) * C180_PI;
   A = cos (dist) * cos (lat1);
   B = sin (dist) * cos (bear) * sin (lat1);
   C = sin (dist) * sin (bear);
   *lon2 = atan2 (A * sin (lon1) + B * sin (lon1) + C * cos (lon1),
                  A * cos (lon1) + B * cos (lon1) -
                  C * sin (lon1)) * C180_PI;
   return 0;
}
