CXX := g++
C11 := -std=c++11
EXE := ../bin/cf2sky.e
SRC := datetime.cpp \
       intrpSP3.cpp \
       rinex.cpp
EXS := skyplot.cpp
GMTV := -DGMT5
CFLAGS   = -c $(C11) -Wall -Wunused-variable $(GMTV)
LFLAGS   = $(C11) -Wall -Wunused-variable $(GMTV)
OBJ := $(SRC:%.cpp=%.o)

all: $(EXE) clean

$(EXE): $(OBJ) $(EXS)
	$(CXX) $(LFLAGS) -o $(EXE) $(EXS) rinex.o intrpSP3.o datetime.o

datetime.o: datetime.cpp datetime.h
	$(CXX) $(CFLAGS) -o datetime.o datetime.cpp
intrpSP3.o: intrpSP3.cpp intrpSP3.h datetime.o
	$(CXX) $(CFLAGS) -o intrpSP3.o intrpSP3.cpp
rinex.o: rinex.cpp rinex.h datetime.o
	$(CXX) $(CFLAGS) -o rinex.o rinex.cpp
	
clean:
	-@rm $(OBJ)
