#include "geolib.hpp"
#include <cmath>

/*
 * GEODETIC TO GEOCENTRIC RECTANGULAR COORDINATES
 * 2013-11-25 16:21:16 
 */

void geo::ell2car(const double& a,const double& f,
  const double& lat,const double& lon, const double& h,
  double& x,double& y,double& z)
{
/*
** This subroutine transforms from geocentric rectangular to 
** geodetic coordinates.
**
** Given:
**    lat         d         Latitude coordinate on the ellipsoid (radians)
**    lon         d         Longitude coordinate on the ellipsoid (radians)
**    h           d         Height coordinate on the ellipsoid
**
** Returned:
**    a           d         Equatorial Radius of the Earth
**    f           d         Flattening form factor
**    x           d         Rectangular X coordinate
**    y           d         Rectangular Y coordinate
**    z           d         Rectangular Z coordinate
*/
  double cosf=std::cos(lat);
  double sinf=std::sin(lat);
  double cosl=std::cos(lon);
  double sinl=std::sin(lon);
  double e2=2.0*f-f*f;
  
  double radius_of_curvature=a/
                      ::sqrt(1.0e00-e2*sinf*sinf);

  x=(radius_of_curvature+h)*cosf*cosl;
  y=(radius_of_curvature+h)*cosf*sinl;
  z=((1.0e00-e2)*radius_of_curvature+h)*sinf;

  return;
}

void geo::ell2car(const geo::ellipsoid& ell,
  const double& lat,const double& lon, const double& h,
  double& x,double& y,double& z)
{
  double cosf=std::cos(lat);
  double sinf=std::sin(lat);
  double cosl=std::cos(lon);
  double sinl=std::sin(lon);
  
  double radius_of_curvature=ell.semimajor()/
                      ::sqrt(1.0e00-ell.eccentricity2()*sinf*sinf);

  x=(radius_of_curvature+h)*cosf*cosl;
  y=(radius_of_curvature+h)*cosf*sinl;
  z=((1.0e00-ell.eccentricity2())*radius_of_curvature+h)*sinf;

  return;
}
