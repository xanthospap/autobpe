#include "geolib.hpp"
#include <iostream>
#include <fstream>
#include <string.h>
#include <sstream>
#include <algorithm>
#include <iterator>
#include <stdexcept>

using std::vector;
using std::string;

static string VERSION     = "v-1.0";
static string NAME        = "xyz2flh";
static string RELEASE     = "beta";
static string LAST_UPDATE = "NOV-2014";

/* a simple point structure */
struct point {
  double x,y,z;
  string name;
};

/* read cartesian coordinates from given line */
bool readcartesian (string&, point&);

/* read geodetic coordinates from given line */
bool readgeodetic (string&, point&, short int FORMAT=0);

/* print information on screen and exit */
int credits ();

/* print help information on screen and exit */
int help ();

/* main function; on success zero is returned */
int main(int argc, char* argv[])
{

  std::istream* in;
  std::ifstream ifn;

  /* output units 0=radians, 1=d.degrees, 2=h.degrees */
  short int OUTPUT_UNIT = 0;

  /* input units 0=radians, 1=d.degrees, 2=h.degrees */
  short int INPUT_UNIT = 0;

  /* 0=normal, 1=inverse (geodetic to cartesian) */
  short int TRANSFORMATION = 0;

  /* Default ellipsoid (GRS80) */
  geo::ellipsoid Ell;

  /* set input buffer to stdin.
  Used when there are cmd's but no file is given
  (i.e. input from stdin $>cat foo | bar.exe -a -b) */
  bool SET_STDIN_BUF = 0;

  /* ------------------------------------
  set the input stream (stdin or file) 
  and read cmd arguments 
  ---------------------------------------*/
  if (argc==1) {
    /* no cmds; read from stdin */
    SET_STDIN_BUF=false;
    in=&std::cin;

  } else {
    SET_STDIN_BUF=true;
    /* read in the cmds */
    for (int i=1;i<argc;i++) {
      std::string cmd=argv[i];
      /* process switches */
      if (cmd[0]=='-') {
        /* output units switch */
        if (cmd[1]=='u') {
          if (cmd.size()<3) {
            std::cerr<<"\nNeed to specify output units!\n";
            return 1;
          } else {
            if (cmd[2]=='r') OUTPUT_UNIT=0;
            else if (cmd[2]=='d') OUTPUT_UNIT=1;
            else if (cmd[2]=='h') OUTPUT_UNIT=2;
            else {
              std::cerr<<"\nInvalid output units!\n";
              return 1;
            }
          }
        } else if (cmd[1]=='t') {
          /* input units switch */
          if (cmd.size()<3) {
            std::cerr<<"\nNeed to specify input units!\n";
            return 1;
          } else {
            if (cmd[2]=='r') INPUT_UNIT=0;
            else if (cmd[2]=='d') INPUT_UNIT=1;
            else if (cmd[2]=='h') INPUT_UNIT=2;
            else {
              std::cerr<<"\nInvalid input units!\n";
              return 1;
            }
          }     
        } else if (cmd[1]=='i') {
          /* do the inverse transformation */
          TRANSFORMATION=1;
        } else if (cmd[1]=='e') {
          /* set the reference ellipsoid */
          if (cmd.size()<3) {
            std::cerr<<"\nNeed to specify ellipsoid name!\n";
            return 1;
          }
          string ellipsoid_name = cmd.substr(2,cmd.size());
          geo::ellipsoid re;
          if (!re.setFromModel (ellipsoid_name)) {
            std::cerr<<"\n";
            return 1;
          }
          Ell=re;
        } else if (cmd[1]=='v') {
          /* credits and exit */
          credits ();
          return 0;
        } else if (cmd[1]=='h') {
          /* help and exit */
          help ();
          return 0;
        } else {
          std::cerr<<"\nUnknown cmd option: "<<cmd<<"; Skipped. (break1)";
          SET_STDIN_BUF = true;
          break;
        }
      } else {
        /* Two possibilities now; if this is the last cmd,
        it could be the input file. Else, it is just an
        unrecognized cmd */
        if (i==argc-1) {
          ifn.open(argv[i]);
          if (!ifn.is_open()) {
            std::cerr<<"\nCould not open file: "<<cmd<<"\n";
            return 1;
          }
          in=&ifn;
          SET_STDIN_BUF=false;
        } else {
          std::cerr<<"\nUnknown cmd option: "<<cmd<<"; Skipped. (break2)";
          SET_STDIN_BUF = true;
          break;
        }
      }
    }
  }

  /* check that the input stream is set; if not set it to stdin */
  if (SET_STDIN_BUF) in=&std::cin;

  /* std::vector of points to transform */
  vector<point> points;

  /* ------------------------------------
  read the points from input stream and
  assign them to a vector
  ---------------------------------------*/
  string line;
  point p;
  /* get first input line */
std::cout<<"\nready to get line ...";
  std::getline (*in, line);
std::cout<<"\ngot line: "<<line;
  while (!in->eof()) { /* keep reading in points until EOF */
    if (!TRANSFORMATION) {
      if (readcartesian (line, p)) points.push_back (p);
    } else {
      if (readgeodetic (line, p, INPUT_UNIT)) points.push_back (p);
    }
    std::getline (*in, line);
  }

  /* ------------------------------------
  transform all points read
  ---------------------------------------*/
  // std::cout<<"\n";
  double f,l,h;
  bool HAS_NAME;

  switch (TRANSFORMATION) {
    case (0):
      for (auto& i : points) {
        geo::car2ell (Ell,i.x,i.y,i.z,f,l,h);
        HAS_NAME=(i.name=="")?false:true;
        switch (OUTPUT_UNIT) {
          case (0) :
            if (!HAS_NAME) printf("%+15.12f %+15.12f %+10.4f\n",f,l,h);
            else printf("%10s %+15.12f %+15.12f %+10.4f\n",i.name.c_str(),f,l,h);
            break;
          case (1):
            double dlat,dlon;
            geo::rad2ddeg(f,dlat);
            geo::rad2ddeg(l,dlon);
            if (!HAS_NAME) printf("%+15.10f %+15.10f %+10.4f\n",
              dlat,dlon,h);
            else printf("%10s %+15.10f %+15.10f %+10.4f\n",
              i.name.c_str(),dlat,dlon,h);
            break;
          case (2):
            int latdeg,latmin,londeg,lonmin;
            double latsec,lonsec;
            geo::rad2hdeg(f,latdeg,latmin,latsec);
            geo::rad2hdeg(l,londeg,lonmin,lonsec);
            if (!HAS_NAME) printf("%+3i %2i %8.5f %+3i %2i %8.5f %+10.4f\n",
              latdeg,latmin,latsec,londeg,lonmin,lonsec,h);
            else
              printf("%10s %+3i %2i %8.5f %+3i %2i %8.5f %+10.4f\n",
                i.name.c_str(),latdeg,latmin,latsec,londeg,lonmin,lonsec,h);
            break;
          default:
            std::cerr<<"\n*** ERROR! Invalid Units";
            return 1;
        }
      }
      break;
    case 1:
      for (auto& i : points) {
        geo::ell2car (Ell,i.x,i.y,i.z,f,l,h);
        HAS_NAME=(i.name=="")?false:true;
        if (!HAS_NAME) printf("%+15.4f %+15.4f %+15.4f\n",f,l,h);
        else printf("%10s %+15.4f %+15.4f %+15.4f\n",i.name.c_str(),f,l,h);
      }
      break;
  }
      

  /* if input file used, close it */
  if (ifn.is_open()) ifn.close ();

  /* all done */
  return 0;
}

/* Format must be: [NAME] x y z */
bool readcartesian (string& str, point& p)
{
  vector<string> tokens;
  /* split the line using whitespace */
  std::istringstream iss (str);
  std::copy (std::istream_iterator<string>(iss),
      std::istream_iterator<string>(),
      std::back_inserter<vector<string> >(tokens));
  /* size must be at least 3 */
  if (tokens.size()<3) return false;
  /* if empty line or the first character is '#' skip the line */
  if (tokens.empty()||tokens[0][0]=='#') return false;
  /* if size of substrings = 3, then immidiatelly read x,y,z;
  else read name x, y, z */
  if (tokens.size()==3) {
    try {
      p.x=std::stod (tokens[0]);
      p.y=std::stod (tokens[1]);
      p.z=std::stod (tokens[2]);
    } catch (std::invalid_argument) {
      std::cerr<<"\nCannot read coordinates from line: "<<str<<"[EC:0]";
      return false;
    }
  } else if (tokens.size()==4) {
    try {
      p.name=tokens[0];
      p.x=std::stod (tokens[1]);
      p.y=std::stod (tokens[2]);
      p.z=std::stod (tokens[3]);
    } catch (std::invalid_argument) {
      std::cerr<<"\nCannot read coordinates from line: "<<str<<"[EC:1]";
      return false;
    }
  } else {
    std::cerr<<"\nCannot read coordinates from line: "<<str<<"[EC:2]";
    return false;
  }

  return true;
}

/* 
 * Format must be: [NAME] latitude longtitude height 
 * FORMAT 0->radians, 1->decimal degrees, 2->hexicondal degrees
*/
bool readgeodetic (string& str, point& p, short int FORMAT)
{
  vector<string> tokens;

  /* split the line using whitespace */
  std::istringstream iss (str);
  std::copy (std::istream_iterator<string>(iss),
      std::istream_iterator<string>(),
      std::back_inserter<vector<string> >(tokens));

  /* if empty line or the first character is '#' skip the line */
  if (tokens.empty()||tokens[0][0]=='#') return false;

  /* 3 discrete cases */
  switch (FORMAT) {
    case 0: /* read radians */
    case 1: /* read decimal degrees */
      /* size must be at least 3 */
      if (tokens.size()<3) return false;
      /* if size of substrings = 3, then immidiatelly read lat,lon,hgt;
      else read name,lat,lon,hgt */
      if (tokens.size()==3) {
        try {
          p.x=std::stod (tokens[0]);
          p.y=std::stod (tokens[1]);
          p.z=std::stod (tokens[2]);
        } catch (std::invalid_argument) {
          std::cerr<<"\nCannot read coordinates from line: "<<str<<"[EC:0]";
          return false;
        }
      } else if (tokens.size()==4) {
        try {
          p.name=tokens[0];
          p.x=std::stod (tokens[1]);
          p.y=std::stod (tokens[2]);
          p.z=std::stod (tokens[3]);
        } catch (std::invalid_argument) {
          std::cerr<<"\nCannot read coordinates from line: "<<str<<"[EC:1]";
          return false;
        }
      } else {
        std::cerr<<"\nCannot read coordinates from line: "<<str<<"[EC:2]";
        return false;
      }
      break;
    case 2: /* read hexicondal degrees */
      int deg, min;
      double sec;
      /* size must be at least 7 */
      if (tokens.size()==7) {
        try {
          deg=std::stoi (tokens[0]);
          min=std::stoi (tokens[1]);
          sec=std::stod (tokens[2]);
          p.x=geo::hdeg2rad (deg, min, sec);
          deg=std::stoi (tokens[3]);
          min=std::stoi (tokens[4]);
          sec=std::stod (tokens[5]);
          p.y=geo::hdeg2rad (deg, min, sec);
          p.z=std::stod (tokens[6]);
        } catch (std::invalid_argument) {
          std::cerr<<"\nCannot read coordinates from line: "<<str<<"[EC:3]";
          return false;
        }
      } else if (tokens.size()==8) {
        try {
          p.name=tokens[0];
          deg=std::stoi (tokens[1]);
          min=std::stoi (tokens[2]);
          sec=std::stod (tokens[3]);
          p.x=geo::hdeg2rad (deg, min, sec);
          deg=std::stoi (tokens[4]);
          min=std::stoi (tokens[5]);
          sec=std::stod (tokens[6]);
          p.y=geo::hdeg2rad (deg, min, sec);
          p.z=std::stod (tokens[7]);
        } catch (std::invalid_argument) {
          std::cerr<<"\nCannot read coordinates from line: "<<str<<"[EC:4]";
          return false;
        }
      } else {
        std::cerr<<"\nCannot read coordinates from line: "<<str<<"[EC:5]";
        return false;
      }
      break;
    default:
      return false;
  }

  if (FORMAT==1) { /* convert degrees to rad */
    p.x=geo::ddeg2rad (p.x);
    p.y=geo::ddeg2rad (p.y);
  }

  return true;
}

int credits ()
{
  printf ("%s %s (%s) %s\n",NAME.c_str(),VERSION.c_str(),RELEASE.c_str(),LAST_UPDATE.c_str());
  return 0;
}
int help ()
{
  printf ("\n******************************************************************************************/");
  printf ("\n Program Name : %s",NAME.c_str());
  printf ("\n Version      : %s",VERSION.c_str());
  printf ("\n Last Update  : %s",LAST_UPDATE.c_str());
  printf ("\n");
  printf ("\n Purpose : Transform from cartesian geocentric to ellipsoidal coordinates,");
  printf ("\n           or or vica-versa.");
  printf ("\n");
  printf (" Usage     : xyz2flh [OPTIONS] [POINTS]");
  printf ("\n");
  printf ("\n Switches:");
  printf ("\n No whitespace character between the option flag and the associated argument(s) is needed.\n");
  printf ("           -u[OPTION] Specify the output units (only applicable when transforming from\n");
  printf ("             geocentric rectangular to geodetic coordinates). User can choose between:\n");
  printf ("             * r for radians,\n");
  printf ("             * d decimal degrees,\n");
  printf ("             * h hexicondal degress\n");
  printf ("           -t[OPTION] Specify the input units (only applicable when transforming from geodetic to\n");
  printf ("             geocentric rectangular coordinates). Options are as above.\n");
  printf ("           -i Perform the inverse transformation, i.e. from geodetic to geocentric cartesian\n");
  printf ("             coordinates.\n");
  printf ("           -u[OPTION] Specify a reference ellipsoid for the transformation. By default GRS80 is used.\n");
  printf ("             User can choose between the following models:\n");
  printf ("             * GRS80,\n");
  printf ("             * ITRF,\n");
  printf ("             * WGS84,\n");
  printf ("             * PZ90\n");
  printf ("           -h Display help message and exit\n");
  printf ("           -v Display version and exit");
  printf ("\n");
  printf ("\n Exit Status:  0 -> OK");
  printf ("\n Exit Status:  1 -> ERROR");
  printf ("\n");
  printf ("\n |===========================================|");
  printf ("\n |** Higher Geodesy Laboratory             **|");
  printf ("\n |** Dionysos Satellite Observatory        **|");
  printf ("\n |** National Tecnical University of Athens**|");
  printf ("\n |===========================================|");
  printf ("\n");
  printf ("\n******************************************************************************************/\n");
  return 0;
}
