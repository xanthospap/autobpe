CXX = g++
OPT = -O3
CFLAGS = -c -std=c++11 -Wall $(OPT)
LFLAGS = -std=c++11 -Wall $(OPT) -I./
LIB = 
SRC = geolib.cpp car2ell.cpp ell2car.cpp
HDR = geolib.hpp
OBJ = $(SRC:%.cpp=%.o)

all : ../bin/xyz2flh clear

../bin/xyz2flh : $(OBJ) $(HDR) xyz2flh.cpp
	$(CXX) $(LFLAGS) $(OBJ) -o ../bin/xyz2flh xyz2flh.cpp

geolib.o : $(HDR) geolib.cpp
	$(CXX) $(CFLAGS) -o geolib.o geolib.cpp
car2ell.o : $(HDR) car2ell.cpp
	$(CXX) $(CFLAGS) -o car2ell.o car2ell.cpp
ell2car.o : $(HDR) ell2car.cpp
	$(CXX) $(CFLAGS) -o ell2car.o ell2car.cpp

clear:
	-@rm geolib.o car2ell.o ell2car.o
