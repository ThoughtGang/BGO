CXX = gcc 

all:
	$(CXX) -g -Wall -fPIC -c libgcci686test.c
	$(CXX) -shared -Wl,-soname,libgcci686test.so.1 -o libgcci686test.so.1.0 *.o
	
clean:
	rm -rf *.o *.so*
