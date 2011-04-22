#!/usr/bin/env ruby
# Usa ruby-elf per parsare il binario elf, stampa i simboli globali definiti
# nella text section del file
#

require 'rubygems' # usato per poter sfruttare la gemma ruby-elf
require 'elf'
require 'pp'


path = "../libctest.so"

begin

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
      puts "#{sym.address_string} #{flag} #{sym.name}#{sym.version}"
    end

  end
rescue Errno::ENOENT
  $stderr.puts " {file}: No such file"
end
