
#include <stdio.h>
#define __USE_GNU
#include <dlfcn.h>


       void ctest1(){
         static void (*test_real)(int *)=NULL;
         void *handle;
  
         printf("42\n");

         handle = dlopen ("/tmp/lib/libctest.so", RTLD_LAZY);
         if(!handle){
           printf("dlopen failed\n");
         }
                                           
         if (!test_real) 
           test_real=dlsym(handle,"ctest1");
       
         printf("test succeeded\n");
         if(test_real != NULL)
           test_real();
         else
           printf("non ha funzionato\n");
      }

       void ctest2(){
         static void (*test_real)(int *)=NULL;
         void *handle;
  
         

         handle = dlopen ("/tmp/lib/libctest.so", RTLD_LAZY);
         if(!handle){
           printf("dlopen failed\n");
         }
                                           
         if (!test_real) 
           test_real=dlsym(handle,"ctest2");
       
         printf("test succeeded\n");
         if(test_real != NULL)
           test_real();
         else
           printf("non ha funzionato\n");
      }
