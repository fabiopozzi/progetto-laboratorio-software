lib_wrap: lib_wrap.o
	gcc -fPIC -Wall -g -c lib_wrap.c

libtest: wrapper.o
	gcc -g -shared -Wl wrapper.o -lc -o libtest.so
	cp libtest.so /tmp/lib

ctest2: ctest2.o
	gcc -fPIC -Wall -g -c ctest2.c

ctest1: ctest1.o
	gcc -fPIC -Wall -g -c ctest1.c

libctest: ctest1.o ctest2.o
	gcc -g -shared -Wl ctest2.o ctest1.o -lc -o libctest.so
	cp libctest.so /tmp/lib/

prog: prog.o test.o ctest1.o ctest2.o
	gcc -Wall -L/tmp/lib prog.c -ltest -ldl -o prog

