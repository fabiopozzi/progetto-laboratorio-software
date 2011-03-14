#!/usr/bin/env ruby
# Usa ruby-elf per parsare il binario elf, stampa i simboli globali definiti
# nella text section del file
#

require 'rubygems' # usato per poter sfruttare la gemma ruby-elf
require 'elf'
require 'pp'

path = "../libctest.so"
wrapper_code = ""

include_part =<<EOS

#include <stdio.h>
#define __USE_GNU
#include <dlfcn.h>

EOS

begin
  params_list = nil
  wrapped_library_path = "/tmp/lib/libctest.so"
  f = File.open("output.c","w+")

  section = '.dynsym'
  Elf::File.open( path ) do |elf|
    addrsize = (elf.elf_class == Elf::Class::Elf32 ? 8 : 16)

    if not elf.has_section? section
      $stderr.puts " #{elf.path} is not a dynamic library"
      exitval = 1
      next
    end

    elf[section].each do |sym|
      next if sym.name == ''
      begin
        flag = sym.nm_code
      rescue Elf::Symbol::UnknownNMCode => e
        $stderr.puts e.message
      end
      next if sym.nm_code != 'T'
      next if sym.name == "_init"
      next if sym.name == "_fini"

      function_name = sym.name

      code_block= <<END_OF_CODE

       void #{function_name}(#{params_list}){
         static void (*test_real)(int *)=NULL;
         void *handle;
             
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
