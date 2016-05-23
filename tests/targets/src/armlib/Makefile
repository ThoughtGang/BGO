CXX = arm-linux-gnueabi-gcc

all:
	$(CXX) -g -Wall -fPIC -c libarmtest.c
	$(CXX) -shared -Wl,-soname,libarmtest.so.1 -o libarmtest.so.1.0 *.o
	
clean: 
	rm -rf *.o *.so*
