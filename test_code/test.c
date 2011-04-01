#include <stdio.h>
#define __USE_GNU
#include <dlfcn.h>


int ctest2(int i){
  static int (*test_real)(int )=NULL;
  void *handle;
  int return_value = 0;

  handle = dlopen ("/tmp/lib/libctest.so", RTLD_LAZY);
  if(!handle){
    printf("dlopen failed\n");
  }

  if (!test_real)
    test_real=dlsym(handle,"ctest2");

  printf("test succeeded\n");
  if(test_real != NULL){
    return_value = test_real(42);
  }
  else{
    printf("non ha funzionato\n");
  }

  return return_value;
}

int ctest1(int i){
  static int (*test_real)(int )=NULL;
  void *handle;
  int return_value = 0;

  handle = dlopen ("/tmp/lib/libctest.so", RTLD_LAZY);
  if(!handle){
    printf("dlopen failed\n");
  }

  if (!test_real)
    test_real=dlsym(handle,"ctest1");

  printf("test succeeded\n");
  if(test_real != NULL){
    return_value = test_real(42);
  }
  else{
    printf("non ha funzionato\n");
  }

  return return_value;
}
