require 'metasm'
include Metasm
require 'pp'

target = '../prog'
bin = AutoExe.decode_file target
dasm = bin.disassemble('main')

retaddr = dasm.function_at('main').return_address.first

puts '[*] main ends at 0x%x' % retaddr
off = 10 
while off > 0
  di = dasm.disassemble_instruction(retaddr - off)
  off -=1
  pp di
end
