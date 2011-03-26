#!/usr/bin/env ruby
# Usa ruby-elf per parsare il binario elf, stampa i simboli globali definiti
# nella text section del file
#
require 'stuff'
require 'rubygems' # usato per poter sfruttare la gemma ruby-elf
require 'elf'
require 'pp'

library = "libctest.so" #da leggere da un config file o da input

path = "../" + library
wrapper_code = ""

include_part =<<EOS

#include <stdio.h>
#define __USE_GNU
#include <dlfcn.h>

EOS

begin
  params_list = nil
  wrapped_library_path = "/tmp/lib/"+ library
  f = File.open("output.c","w+")

  section = '.dynsym' #ci interessano solo i simboli globali definiti nella libreria
  Elf::File.open( path ) do |elf|
    addrsize = (elf.elf_class == Elf::Class::Elf32 ? 8 : 16)

    unless elf.has_section? section
      abort(" #{elf.path} is not a dynamic library")
    end

    elf[section].each do |sym|
      next if sym.name == ''
      begin
        flag = sym.nm_code
      rescue Elf::Symbol::UnknownNMCode => e
        $stderr.puts e.message
      end
      next if sym.nm_code != 'T' # considero solo i simboli dichiarati nella .text section
      next if sym.name == "_init" # salto anche _init e _fini
      next if sym.name == "_fini"

      function_name = sym.name
      #params_list = Stuff.get_params_from_process
      #params_list = get_params_from_include

      wrapped_code = Stuff.init_wrappers(library)
      #{wrapped_code[function_name]} # inserito nel code_block permette di definire un hash 
      # che ad ogni funzione fa corrispondere il codice da inserire nella funzione wrapper
      code_block= <<END_OF_CODE

       void #{function_name}(#{params_list}){
         static void (*test_real)(int *)=NULL;
         void *handle;
  
         #{wrapped_code[function_name]}

         handle = dlopen ("#{wrapped_library_path}", RTLD_LAZY);
         if(!handle){
           printf("dlopen failed\\n");
         }
                                           
         if (!test_real) 
           test_real=dlsym(handle,"#{function_name}");
       
         printf("test succeeded\\n");
         if(test_real != NULL)
           test_real(#{params_list});
         else
           printf("non ha funzionato\\n");
      }
END_OF_CODE
      wrapper_code << code_block
      puts "#{sym.address_string} #{flag} #{sym.name}#{sym.version}"
    end

  end
rescue Errno::ENOENT
  $stderr.puts " {file}: No such file"
end

f.puts(include_part)
f.puts(wrapper_code)
f.close
