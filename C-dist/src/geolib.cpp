#include "geolib.hpp"
#include <cmath>

geo::ellipsoid::ellipsoid (const std::string& n)
{
  mname = n;
  /* search for ellipsoid name */
  if (n=="GRS80") {
    a = 6378137.0;
    f = 1.0e00/298.25722210088;
  } else if (n=="ITRF") {
    a = 6378137.0;
    f = 1.0e00/298.25722210088;
  } else if (n=="WGS84") {
    a = 6378137.0;
    f = 1.0e00/298.257223563;
  } else if (n=="PZ90") {
    a = 6378137.0;
    f = 1.0e00/298.257223563;
  } else {
    /* error! set to default GRS80 */
    std::cerr<<"\n*** Unknown Ellipsoid/datum: "<<n;
    a = 6378137.0;
    f = 1.0e00/298.25722210088;
    mname="GRS80";
  }
}

bool geo::ellipsoid::setFromModel (const std::string& n)
{
  /* search for ellipsoid name */
  if (n=="GRS80") {
    a = 6378137.0;
    f = 1.0e00/298.25722210088;
    mname=n;
  } else if (n=="ITRF") {
    a = 6378137.0;
    f = 1.0e00/298.25722210088;
    mname=n;
  } else if (n=="WGS84") {
    a = 6378137.0;
    f = 1.0e00/298.257223563;
    mname=n;
  } else if (n=="PZ90") {
    a = 6378137.0;
    f = 1.0e00/298.257223563;
    mname=n;
  } else {
    /* error! */
    std::cerr<<"\n*** Unknown Ellipsoid/datum: "<<n;
    return false;
  }

  return true;
}


void geo::rad2hdeg(const double& arad,
  int& deg,int& min,double& sec)
{
  double rad = fabs(arad);

  double ddeg = rad * (180.0e00 / DPI);
  double temp,d_deg,d_min;

  temp = modf (ddeg,&d_deg);
  deg = static_cast<int>(d_deg);
  temp *= 60.0e00;
  
  sec = modf (temp,&d_min);
  min = static_cast<int>(d_min);

  sec *= 60.0e00;

  if (rad<0) deg = -1 * deg;
  
  return;
}
