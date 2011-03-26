#!/usr/bin/env ruby
$LOAD_PATH << './lib'
require 'function_hook.rb'
require 'pp'

module Stuff
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
end

Stuff.get_params_from_process
