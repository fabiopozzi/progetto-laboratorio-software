#!/usr/bin/env ruby

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
end
