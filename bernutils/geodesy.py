import math

class Ellipsoid:
  ''' A class to represent a Reference Ellipsoid. It can be a "standard" ellipsoid,
      e.g. WGS84, GRS80, etc., or a user-defined one. This depends on the instance
      construction (see the constructor or whatever Pythons calls constructors by)
  '''

  def __init__(self, *args, **kwargs):
    ''' Constructing an ellipsoid can be done in one of two ways :

        * Construct a standard ellipsoid, e.g. ::

            refel = Ellipsoid('GRS80')

          use ``Ellipsoid('NAME')``, where ``'NAME'`` is one of:

          #. 'GRS80'
          #. 'WGS84'
          #. 'PZ90'

        * Construct a user-defined ellipsoid, e.g ::

            refel = Ellipsoid(a=6378137.0, f=.00335281, name='my ell'),

          where the parameter ``name`` is optional.

    '''
    if len(args) == 1: ## Construct from ellipsoid name

      if args[0] == 'GRS80':
        self.__a = 6378137.0e0
        self.__f = 1.0e00/298.257222101e0
        self.__name = 'GRS80'
      elif args[0] == 'WGS84':
        self.__a = 6378137.0e0
        self.__f = 1.0e00/298.257223563e0
        self.__name = 'WGS84'
      elif args[0] == 'PZ90':
        self.__a = 6378135.0e0
        self.__f = 1.0e00/298.257839303e0
        self.__name = 'PZ90'
      else:
        raise RuntimeError('Invalid ellipsoid name [%s]' %args[0])

    elif len(kwargs) >= 1: ## Construct a user-define ellipsoid

      self.__a = kwargs['a']
      self.__f = kwargs['f']
      if 'name' in kwargs: 
        self.__name = kwargs['name']
      else:
        self.__name = 'user-defined'

    else:
      raise RuntimeError('Invalid ellipsoid initialization')

  def semiMajorAxis(self):
    ''' return the Semi-Major Axis (i.e. parameter ``a``)
    '''
    return self.__a

  def flattening(self):
    ''' return the Flattening (i.e. parameter ``f``)
    '''
    return self.__f

  def name(self):
    ''' return the ellipsoid's name
    '''
    return self.__name

  def eccentricitySquared(self):
    ''' return the Eccentricity squared (i.e. parameter ``e**2``)
    '''
    return ( 2.0e0 - self.__f ) * self.__f

  def semiMinorAxis(self):
    ''' return the Semi-Minor Axis (i.e. parameter ``b``)
    '''
    return self.__a - self.eccentricitySquared() * self.__a

  def radiusOfCurvature(self, lat):
    ''' Compute the normal radious of curvature at a given latitude. See
        Physical Geodesy, p. 194
    '''
    cosf  = math.cos(lat)
    sinf  = math.sin(lat)
    acosf = self.__a * cosf
    bsinf = self.semiMinorAxis() * sinf
    den   = math.sqrt(acosf*acosf + bsinf*bsinf)
    return (self.__a * self.__a) / den

def cartesian2ellipsoidal(x, y, z, ellipsoid=None):
  ''' Given a set of geocentric, cartesian coordinates and optionaly a reference
      ellispoid, transform the set to ellipsoidal coordinates, i.e. longtitude,
      latitude and (ellipsoidal) height.
  '''

  if ellipsoid == None:
    ellipsoid = Ellipsoid('GRS80')

  ## Functions of ellipsoid parameters.
  a     = ellipsoid.semiMajorAxis()
  f     = ellipsoid.flattening()
  aeps2 = a*a*1e-32
  e2    = (2.0e0-f)*f
  e4t   = e2*e2*1.5e0
  ep2   = 1.0e0-e2
  ep    = math.sqrt(ep2)
  aep   = a*ep

  ''' Compute Coefficients of (Modified) Quartic Equation
      Remark: Coefficients are rescaled by dividing by 'a'
  '''

  ## Compute distance from polar axis squared.
  p2 = x*x + y*y

  ## Compute longitude lon
  if p2 != .0e0:
    lon = math.atan2(y, x)
  else:
    lon = .0e0

  ## Ensure that Z-coordinate is unsigned.
  absz = abs(z)

  if p2 > aeps2: ## Continue unless at the poles

    ## Compute distance from polar axis.
    p = math.sqrt(p2)
    ## Normalize.
    s0 = absz/a
    pn = p/a
    zp = ep*s0 
    ## Prepare Newton correction factors.
    c0  = ep*pn 
    c02 = c0*c0 
    c03 = c02*c0 
    s02 = s0*s0 
    s03 = s02*s0 
    a02 = c02+s02 
    a0  = math.sqrt(a02) 
    a03 = a02*a0 
    d0  = zp*a03 + e2*s03 
    f0  = pn*a03 - e2*c03 
    ## Prepare Halley correction factor.
    b0 = e4t*s02*c02*pn*(a0-ep) 
    s1 = d0*f0 - b0*s0 
    cp = ep*(f0*f0-b0*c0) 
    ## Evaluate latitude and height.
    lat = math.atan(s1/cp)
    s12 = s1*s1 
    cp2 = cp*cp 
    hgt = (p*cp+absz*s1-a*math.sqrt(ep2*s12+cp2))/math.sqrt(s12+cp2);

  else: ## Special case: pole.

    lat = math.pi / 2e0;
    hgt = absz - aep;

  ## Restore sign of latitude.
  if z < 0.e0:
    lat = -lat

  return lon, lat, hgt

def ellipsoidal2cartesian(lon, lat, hgt, ellipsoid=None):
  ''' Given a set of geocentric, ellipsoidal coordinates and optionaly a reference
      ellispoid, transform the set to cartesian coordinates, i.e. x, y, z.
  '''

  if ellipsoid == None:
    ellipsoid = Ellipsoid('GRS80')

  ## Eccentricity squared.
  e2 = ellipsoid.eccentricitySquared()

  ## Trigonometric numbers.
  sinf = math.sin(lat)
  cosf = math.cos(lat)
  sinl = math.sin(lon)
  cosl = math.cos(lon)

  ## Radius of curvature in the prime vertical.
  N = ellipsoid.radiusOfCurvature(lat)

  ## Compute geocentric rectangular coordinates.
  x = (N+h) * cosf * cosl
  y = (N+h) * cosf * sinl
  z = ((1.0e0-e2) * N + h) * sinf

  return x, y, z

def cartesian2topocentric(xi, yi, zi, xj, yj, zj, ellipsoid=None):
  ''' Given two points on the ellispoid, described by their geocentric, cartesian
      coordinates (i.e. [xi, yi, zi] for the reference point and [xj, yj, zj] for the rover)
      return the difference vector in the topocentric reference frame (around
      the reference point).
  '''

  ## Ellipsoidal coordinates of reference point.
  lambda_i, phi_i, h_i, = cartesian2ellipsoidal(xi, yi, zi, ellipsoid)

  ## Trigonometric numbers.
  cosf = math.cos(phi_i)
  cosl = math.cos(lambda_i)
  sinf = math.sin(phi_i)
  sinl = math.sin(lambda_i)

  ## Catresian vector.
  dx = xj - xi
  dy = yj - yi
  dz = zj - zi

  ## Topocentric vector.
  north = - sinf * cosl * dx - sinf * sinl * dy + cosf * dz
  east  = - sinl * dx        + cosl * dy
  up    =   cosf * cosl * dx + cosf * sinl * dy + sinf * dz

  return north, east, up

def topocentric2azd(north, east, up):
  ''' Given a (topocentric) vector, compute the azimouth, zenith angle and distance.
  '''

  ## spatial distance of vector
  distance  = math.sqrt(north*north + east*east + up*up)

  ## check if zero distance or north are zero
  if  distance == .0e0 or north == .0e0:
    raise RuntimeError('geodesy::top2daz -> Zero Division !!')

  ## azimouth
  a = math.atan2(east,north)

  ## normalize to range [0-2pi)
  azimouth  = math.fmod(a, math.pi*2.0e0);
  while azimouth < .0: azimouth += (math.pi*2.0e0)

  ## zenith angle [0-pi)
  zenith = math.acos(up / distance)

  return azimouth, zenith, distance