require 'rubygems'
require 'cast'

FILENAME = "prova.c"

# grezzo modo per rimuovere gli include che
# non vengono riconosciuti dal parser
def remove_preprocessor(file)
  code = Array.new
  file.each do |line|
    unless line[0].chr == '#'
      code << line
    end
  end
  return code
end


def parse_source_file(filename)
  parser = C::Parser.new

  f = File.open( filename )
  codice = remove_preprocessor(f)
  #puts codice
  parser.pos.filename = filename

  parser.type_names << 'LinkedList'

  #ugly_c_code = open("../prog.c"){ |f| f.read }
  #tree = parser.parse(ugly_c_code)
  tree = parser.parse(codice)
  tree
end

def try_to_find_methods( tree )
  tree.entities.each do |node|
    node.Declaration? or next #skip everything that's not a definition
    node.declarators.each do |decl|
      if decl.type.Function?
        puts decl.name
      end
    end
  end
end


albero = parse_source_file( FILENAME )
try_to_find_methods( albero )
#p albero

