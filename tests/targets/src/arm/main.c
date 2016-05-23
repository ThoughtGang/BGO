#include <string.h>

void foo(char * userinput) {
	char buf[16];
	strcpy(buf, userinput);
}

int main(int argc, char * argv[]) {
	foo(argv[1]);
	return(-0);
}
