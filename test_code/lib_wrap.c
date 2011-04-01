#include <stdio.h>
#define __USE_GNU
#include <dlfcn.h>

int ctest1(int i){
  static void (*test_real)(int )=NULL;
  void *handle;
  
  handle = dlopen ("/tmp/lib/libctest.so", RTLD_LAZY);
  if(!handle){
		printf("dlopen failed\n");
	}
  
  if (!test_real) 
	test_real=dlsym(handle,"ctest1");

	printf("test succeeded\n");
	if(test_real != NULL)
		test_real(10);
	else
		printf("non ha funzionato\n");

	return 0;
}

int ctest2(int i){
  static void (*test_real)(int )=NULL;
  void *handle;
  
  handle = dlopen ("/tmp/lib/libctest.so", RTLD_LAZY);
  if(!handle){
		printf("dlopen failed\n");
	}
  
  if (!test_real) 
	test_real=dlsym(handle,"ctest2");

	printf("test succeeded\n");
	if(test_real != NULL)
		test_real(10);
	else
		printf("non ha funzionato\n");

	return 0;
}
