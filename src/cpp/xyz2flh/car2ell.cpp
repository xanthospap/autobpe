#include "geolib.hpp"
#include <cmath>

/*
 * GEOCENTRIC RECTANGULAR TO GEODETIC COORDINATES
 * 2013-11-25 16:21:16 
 */

void geo::car2ell(const double& a,const double& f,
  const double& x,const double& y, const double& z,
  double& phi,double& lambda,double& h)
{
/*
** This subroutine transforms from geocentric rectangular to 
** geodetic coordinates.
**
** Given:
**    a           d         Equatorial Radius of the Earth (Note 1)
**    f           d         Flattening form factor (Note 2)
**    x           d         Rectangular X coordinate (Note 3)
**    y           d         Rectangular Y coordinate (Note 3)
**    z           d         Rectangular Z coordinate (Note 3)
**
** Returned:
**    phi         d         Latitude coordinate on the ellipsoid (Note 4)
**    lambda      d         Longitude coordinate on the ellipsoid (Note 4)
**    h           d         Height coordinate on the ellipsoid (Note 3)
**
** Notes:
**
** 1) The parameter given is from the 1980 Geodetic Reference System, which
**    was adopted at the XVII General Assembly of the International Union
**    of Geodesy and Geophysics (IUGG).  It is expressed in meters.
**
** 2) The parameter given is from the 1980 Geodetic Reference System, which
**    was adopted at the XVII General Assembly of the International Union
**    of Geodesy and Geophysics (IUGG).  It is a dimensionless quantity.
**
** 3) Coordinates are expressed in meters.
**
** 4) Coordinates are expressed in radians.
**
** 5) This routine is closely based on the GCONV2H subroutine by
**    Toshio Fukushima (See reference 1).
**
** 6) This version of the routine uses the GRS 1980 ellipsoid parameters
**    as the given default. The user may choose to use other ellipsoids as input parameters.
**
** Test case:
**    given input: x = 4075579.496D0 meters  Wettzell (TIGO) station
**                 y =  931853.192D0 meters
**                 z = 4801569.002D0 meters
**
**    expected output: phi    =   0.857728298603D0 radians
**                     lambda =   0.224779294628D0 radians
**                     h      = 665.9207D0 meters
**
** References:
**
**    Fukushima, T., "Transformation from Cartesian to geodetic
**    coordinates accelerated by Halley's method", J. Geodesy (2006),
**    79(12): 689-693
**
**    Petit, G. and Luzum, B. (eds.), IERS Conventions (2010),
**    IERS Technical Note No. 36, BKG (2010)
**
** Revisions:
**    2006              T.   Fukushima             Original code
**    2010 March 19     B.E. Stetzler              Added header and copyright
**    2010 March 19     B.E. Stetzler              Initial standardization
**                                                 of code, capitalized
**                                                 variables for FORTRAN
**                                                 77 backwards compatibility
**    2010 March 22      B.E. Stetzler             Provided test case
**    2010 September 2   B.E. Stetzler             Corrected F to match Table
**                                                 1.2 of IERS Conventions
**                                                 (2010) and updated test case
*-----------------------------------------------------------------------*/


/* Functions of ellipsoid parameters */
  const double aeps2 = a*a*1e-32;
  const double e2    = (2.0e0-f)*f;
  const double e4t   = e2*e2*1.5e0;
  const double ep2   = 1.0e0-e2;
  const double ep    = ::sqrt(ep2);
  const double aep   = a*ep;

/* ---------------------------------------------------------
* Compute Coefficients of (Modified) Quartic Equation
*
* Remark: Coefficients are rescaled by dividing by 'a'
* ---------------------------------------------------------*/

  /* Compute distance from polar axis squared */
  double p2 (x*x+y*y);

  /* Compute longitude lambda  */
  if (p2)
    lambda = ::atan2(y,x);
  else
    lambda=.0;

  /* Ensure that Z-coordinate is unsigned */
  double absz = fabs(z);

  /* Continue unless at the poles */
  if (p2>aeps2) {
    /* Compute distance from polar axis */
    double p = ::sqrt(p2);
    /* Normalize */
    double s0 = absz/a;
    double pn = p/a;
    double zp = ep*s0;
    /* Prepare Newton correction factors. */
    double c0  = ep*pn;
    double c02 = c0*c0;
    double c03 = c02*c0;
    double s02 = s0*s0;
    double s03 = s02*s0;
    double a02 = c02+s02;
    double a0  = ::sqrt(a02);
    double a03 = a02*a0;
    double d0  = zp*a03 + e2*s03;
    double f0  = pn*a03 - e2*c03;
    /* Prepare Halley correction factor. */
    double b0 = e4t*s02*c02*pn*(a0-ep);
    double s1 = d0*f0 - b0*s0;
    double cp = ep*(f0*f0-b0*c0);
    /* Evaluate latitude and height. */
    phi = ::atan(s1/cp);
    double s12 = s1*s1;
    double cp2 = cp*cp;
    h = (p*cp+absz*s1-a*::sqrt(ep2*s12+cp2))/::sqrt(s12+cp2);
  } else {
  /* Special case: pole. */
    phi = DPI/2e0;
    h   = absz - aep;
  }

  /* Restore sign of latitude. */
  if (z<0.)
    phi = -phi;

/* Finished. */
  return;
}

void geo::car2ell(const ellipsoid& ell,
  const double& x,const double& y, const double& z,
  double& phi,double& lambda,double& h)
{
  const double a = ell.semimajor ();
  const double f = ell.flattening ();
  car2ell (a,f,x,y,z,phi,lambda,h);
  return;
}
