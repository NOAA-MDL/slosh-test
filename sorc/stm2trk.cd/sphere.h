#ifndef SPHERE_H
#define SPHERE_H

/* f_radian = Return the answer in radians (Input)
 *     lat1 = The (unprojected) latitude of point 1 (degrees) (Input)
 *     lon1 = The (unprojected) longitude of point 1 (neg west degrees) (In)
 *     lat2 = The (unprojected) latitude of point 2 (degrees) (Input)
 *     lon2 = The (unprojected) longitude of point 2 (neg west degrees) (In)
 *    theta = The direction from point 1 to point 2 (Output) */
void BearCompute (int f_radian, double lat1, double lon1, double lat2,
                  double lon2, double *theta);

/*    R = Radius of earth to use (km) (6371.2 : GRIB2) (6367.47 : GRIB1)
 *        (60nm = 1 degree => 2 pi R = 360 * 60 nm => R = 6366.7070 km)
 * unit = Return distance in: 0 (nautical miles), 1 (statute miles), 2 km
 * lat1 = The (unprojected) latitude of point 1 (degrees) (Input)
 * lon1 = The (unprojected) longitude of point 1 (neg west degrees) (In)
 * lat2 = The (unprojected) latitude of point 2 (degrees) (Input)
 * lon2 = The (unprojected) longitude of point 2 (neg west degrees) (In)
 * dist = The distance from point 1 to point 2 (Output) */
int DistCompute (double R, int unit, double lat1, double lon1, double lat2,
                 double lon2, double *dist);

/*    R = Radius of earth to use (km) (6371.2 : GRIB2) (6367.47 : GRIB1)
 *        (60nm = 1 degree => 2 pi R = 360 * 60 nm => R = 6366.7070 km)
 * unit = "dist" is in: 0 (nautical miles), 1 (statute miles), 2 km
 * lat1 = The (unprojected) latitude of point 1 (degrees) (Input)
 * lon1 = The (unprojected) longitude of point 1 (neg west degrees) (In)
 * dist = The distance to travel on the sphere. (Input)
 * bear = The direction from point 1 to travel (in degrees from N) (Input)
 * lat2 = The (unprojected) latitude of point 2 (degrees) (Output)
 * lon2 = The (unprojected) longitude of point 2 (neg west degrees) (Out) */
int LatLonCompute (double R, int unit, double lat1, double lon1, double dist,
                   double bear, double *lat2, double *lon2);

#endif
