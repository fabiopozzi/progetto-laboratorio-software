#!/usr/bin/env ruby

module Stuff
  def Stuff.init_wrappers(library_name)
    code = Hash.new
    #puts "when I grow up I want to be a real method!" 
    if library_name == "libctest.so"
      code["ctest1"] = "printf(\"42\\n\");" #in questo modo assegno il codice che verra' inserito all'interno del wrapper della funzione ctest1
    end
    code
  end
end
