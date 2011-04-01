#!/usr/bin/env ruby
$LOAD_PATH << './lib'
require 'rubygems' # usato per poter sfruttare la gemma ruby-elf
require 'function_hook.rb'
require 'pp'
require 'elf'

module Stuff
  OPTIONS_FILE = './options'
  def Stuff.init_wrappers(library_name)
    # Returns an hash containing the code to be inserted in each wrapper function.
    # Author:: Fabio Pozzi (mailto:pozzi.fabio@gmail.com)
    #
    # License:: GPL

    # Params:
    # +library_name+:: name of the library you are wrapping.
    code = Hash.new
    if library_name == "libctest.so"
      code["ctest1"] = "printf(\"42\\n\");" #in questo modo assegno il codice che verra' inserito all'interno del wrapper della funzione ctest1
    end
    code
  end

  def Stuff.get_params_from_process
  h_hash = [{ :function => 'ctest1'},{:function => 'ctest2'}]
  #h_hash = [{ :function => 'ctest2'}]
  # run our Hook engine on a running 'notepad' instance
  l = LibraryHook.new('prog', h_hash)
        argomenti = l.get_arguments #get infos about wrapped functions
        pp argomenti
        argomenti
  end

  # Il metodo apre il file contenente tutti i punti di interesse dello stato
  # # e cerca un match, restituendo un array con tutti i risultati del grep
  def Stuff.file_grep( search_string)
    results = Array.new
    #puts search_string
    File.open( OPTIONS_FILE ) do |fh|
      fh.grep( /(.*)#{search_string}(.*)/ ) do |line|
        results << line
      end
    end
    results
  end

  def Stuff.get_library_name
    raw_line = Stuff.file_grep("LIB")
    line = raw_line.first.chomp
    #pp raw_line

    name_array = line.split(/ /)   #LIB=<tab>library_name is the configuration schema
    #puts name_array[1]
    return name_array[1] # the name is the 2nd element, the one after the token separator
  end

  def Stuff.get_functions_list
    # Retrieves a list of functions to be wrapped by our code
    list = Array.new
    raw_list = Stuff.file_grep("FUNCTION")
    raw_list.each do |line|
      line = line.chomp # removes trailing whitespace and '\n'
      el = Hash.new
      name_array = line.split(/ /)
      el[:function]=name_array[1]
      list << el
    end
    list
  end

  def Stuff.get_arguments(libname)
    base_path = "../"
    libpath = base_path + libname
    begin
      section = '.dynsym'
      Elf::File.open( libpath ) do |elf|
      addrsize = (elf.elf_class == Elf::Class::Elf32 ? 8 : 16)

      if not elf.has_section? section
        $stderr.puts " #{elf.path} is not a dynamic library"
        exitval = 1
        next
      end
      symbols = Array.new
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
          puts "#{sym.address_string} #{flag} #{sym.name}#{sym.version}"
          symbols << sym
        end
      end
    rescue Errno::ENOENT
      $stderr.puts " {file}: No such file"
    end
    symbols
  end # end of get_arguments

end

#Stuff.get_params_from_process
libname = Stuff.get_library_name
wrapme = Stuff.get_functions_list
pp wrapme
Generators.generate_hooks(libname)
l = LibraryHook.new('prog', wrapme)
argomenti = l.get_arguments #get infos about wrapped functions
pp argomenti
