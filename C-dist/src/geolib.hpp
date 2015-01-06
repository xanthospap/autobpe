#ifndef GEOLIB_HPP
#define GEOLIB_HPP

#include <iostream>

namespace geo {

/************ CONSTANTS *******************************/
/* Pi */
#define DPI (3.141592653589793238462643)
/* 2Pi */
#define D2PI (6.283185307179586476925287)
/* Degrees to radians */
#define DD2R (1.745329251994329576923691e-2)
/* Radians to seconds */
#define DRAD2SEC (86400e0 / D2PI)
/* Radians to arcseconds */
#define DR2AS (206264.8062470963551564734)
/* Arcseconds to radians */
#define DAS2R (4.848136811095359935899141e-6)
/* Seconds of time to radians */
#define DS2R (7.272205216643039903848712e-5)
/* Arcseconds in a full circle */
#define TURNAS (1296000.0)
/* Milliarcseconds to radians */
#define DMAS2R (DAS2R / 1e3)
/* Length of tropical year B1900 (days) */
#define DTY (365.242198781)
/* Seconds per day. */
#define DAYSEC (86400.0e00)
/* Days per Julian year */
#define DJY (365.25)
/* Days per Julian century */
#define DJC (36525.0)
/* Days per Julian millennium */
#define DJM (365250.0)
/* Reference epoch (J2000.0), Julian Date */
#define DJ00 (2451545.0)
/* Julian Date of Modified Julian Date zero */
#define DJM0 (2400000.5)
/* Reference epoch (J2000.0), Modified Julian Date */
#define DJM00 (51544.5)
/******************************************************/

/* Ellipsoid class */
class ellipsoid 
{
  public:
    ellipsoid():a(6378137.0),f(0.003352810681225),mname("GRS80"){};
    ellipsoid(const std::string&);
    ellipsoid(double& aa,double& ff):a(aa),f(ff),mname("USER-DEFINED"){};
    /* get geometric elements */
    inline double flattening () const {return f;}
    inline double semimajor () const {return a;}
    inline double invflattening () const {return 1.0e00/f;}
    inline double semiminor () const {return a-a*f;}
    inline double eccentricity2 () const {return 2.0*f-f*f;}
    inline std::string name () const {return mname;}
    /* set from a model */
    bool setFromModel (const std::string&);
  private:
    /* defining parameters */
    double a;/*Semi-major axis*/
    double f;/*flattening*/
    std::string mname;
};

/* Convert radians to decimal degrees */
inline void rad2ddeg (const double& rad,double& ddeg)
{
  ddeg = rad * (180.0e00 / DPI);
  return;
}

/* Convert radians to hexicondal degrees */
void rad2hdeg (const double& rad, int& deg,int& min,double& sec);

/* Convert decimal degrees to radians */
inline double ddeg2rad (const double& deg)
{
  return deg*DD2R;
}

/* Convert hexicondal degrees to radians */
inline double hdeg2rad (const int& deg, const int& min, const double& sec)
{
  return (sec/3600.0e00+min/60.0e00+deg)*DD2R;
}

/*
** transform cartesian coordinates to ellipsoidal
** given an ellipsoid, or ...
*/
void car2ell(const ellipsoid& ell,
  const double& x,const double& y, const double& z,
  double& phi,double& lambda,double& h);
/* ... given semi-major axis and flattening */
void car2ell(const double& a,const double& f,
  const double& x,const double& y, const double& z,
  double& phi,double& lambda,double& h);

/*
** transform ellipsoidal coordinates to cartesian
** given an ellipsoid, or ...
*/
void ell2car(const ellipsoid& ell,
  const double& lat,const double& lon, const double& h,
  double& x,double& y,double& z);
/* ... given semi-major axis and flattening */
void ell2car(const double& a,const double& f,
  const double& lat,const double& lon, const double& h,
  double& x,double& y,double& z);

};

#endif
