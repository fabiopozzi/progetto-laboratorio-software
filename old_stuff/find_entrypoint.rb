require 'metasm'
include Metasm
require 'pp'

target = '../prog'
bin = AutoExe.decode_file target
dasm = bin.disassemble('main')

#retaddr = dasm.function_at('main').return_address.first

entry_point = dasm.entrypoints
pp entry_point
#puts '[*] main begins at 0x%x' % entry_point
#off = 10 
#while off > 0
#  di = dasm.disassemble_instruction(retaddr - off)
#  off -=1
#  pp di
#end
