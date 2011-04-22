require 'bombshell'

module Wrapper
    class Interceptor < Bombshell::Environment
      include Bombshell::Shell
      prompt_with 'interceptor'

      # costanti
      DEFAULT_OPTION_FILE = './options'
      DEFAULT_OUTPUT_FILE = './output.rb'
      @actual_output_file = ''
      @option_filename = nil
      LOGLEVEL = 1

      #codice male indentato causa stringa multi linea
      def generate( library_name, functions, output_file = DEFAULT_OUTPUT_FILE )
      tmp = output_file.split('/') #I assume the path includes slashes
      puts tmp[tmp.length-1] unless tmp[1].nil?
      @actual_output_file = output_file
fixed_part =<<'EOS'
#   Versione customizzata e modificata di dbg-apihook contenuto in metasm
#    This file is part of Metasm, the Ruby assembly manipulation suite
#    Copyright (C) 2006-2009 Yoann GUILLOT
#
#    Licence is LGPL, see LICENCE in the top-level directory

# This sample defines an ApiHook class, that you can subclass to easily hook functions
# in a debugged process. Your custom function will get called whenever an API function is,
# giving you access to the arguments, you can also take control just before control returns
# to the caller.
# See the example in the end for more details.

require 'metasm'

class ApiHook
	# rewrite this function to list the hooks you want
	# return an array of hashes
	def setup
	end

	# initialized from a Debugger or a process description that will be debugged
	# sets the hooks up, then run_forever
	def initialize(dbg)
		if not dbg.kind_of? Metasm::Debugger
			process = Metasm::OS.current.find_process(dbg)
			raise "no such process" if not process
			dbg = process.debugger
		end
		dbg.loadallsyms
		@dbg = dbg
		setup.each { |h| setup_hook(h) }
		init_prerun if respond_to?(:init_prerun)	# allow subclass to do stuff before main loop
		@dbg.run_forever
	end

	# setup one function hook
	def setup_hook(h)
		pre  =  "pre_#{h[:hookname] || h[:function]}"
		post = "post_#{h[:hookname] || h[:function]}"

		@nargs = h[:nargs] || method(pre).arity if respond_to?(pre)

		if target = h[:address]
		elsif target = h[:rva]
			modbase = @dbg.modulemap[h[:module]]
			raise "cant find module #{h[:module]} in #{@dbg.modulemap.join(', ')}" if not modbase
			target += modbase[0]
		else
			target = h[:function]
		end

		@dbg.bpx(target) {
			catch(:finish) {
				@cur_abi = h[:abi]
				@ret_longlong = h[:ret_longlong]
				if respond_to? pre
					args = read_arglist
					send pre, *args
				end
				if respond_to? post
					@dbg.bpx(@dbg.func_retaddr, true) {
						retval = read_ret
						send post, retval, args
					}
				end
			}
		}
	end

	# retrieve the arglist at func entry, from @nargs & @cur_abi
	def read_arglist
		nr = @nargs
		args = []

		if (@cur_abi == :fastcall or @cur_abi == :thiscall) and nr > 0
			args << @dbg.get_reg_value(:ecx)
			nr -= 1
		end

		if @cur_abi == :fastcall and nr > 0
			args << @dbg.get_reg_value(:edx)
			nr -= 1
		end

		nr.times { |i| args << @dbg.func_arg(i) }

		args
       	end

	# retrieve the function returned value
	def read_ret
		ret = @dbg.func_retval
		if @ret_longlong
			ret = (ret & 0xffffffff) | (@dbg[:edx] << 32)
		end
		ret
	end

	# patch the value of an argument
	# only valid in pre_hook
	# nr starts at 0
	def patch_arg(nr, value)
		case @cur_abi
		when :fastcall
			case nr
			when 0
				@dbg.set_reg_value(:ecx, value)
				return
			when 1
				@dbg.set_reg_value(:edx, value)
				return
			else
				nr -= 2
			end
		when :thiscall
			case nr
			when 0
				@dbg.set_reg_value(:ecx, value)
				return
			else
				nr -= 1
			end
		end

		@dbg.func_arg_set(nr, value)
	end

	# patch the function return value
	# only valid post_hook
	def patch_ret(val)
		if @ret_longlong
			@dbg.set_reg_value(:edx, (val >> 32) & 0xffffffff)
			val &= 0xffffffff
		end
		@dbg.func_retval_set(val)
	end

	# skip the function call
	# only valid in pre_hook
	def finish(retval)
		patch_ret(retval)
		@dbg.ip = @dbg.func_retaddr
		case @cur_abi
		when :fastcall
			@dbg[:esp] += 4*(@nargs-2) if @nargs > 2
		when :thiscall
			@dbg[:esp] += 4*(@nargs-1) if @nargs > 1
		when :stdcall
			@dbg[:esp] += 4*@nargs
		end
		@dbg.sp += @dbg.cpu.size/8
		throw :finish
	end
end


# This is the class you have to define to hook a function
#
# setup() defines the list of hooks as an array of hashes
# for exported functions, simply use :function => function name
# for arbitrary hook, :module => 'module.dll', :rva => 0x1234, :hookname => 'myhook' (call pre_myhook/post_myhook)
# :abi can be :stdcall (windows standard export), :fastcall or :thiscall, leave empty for cdecl
# if pre_<function> is defined, it is called whenever the function is entered, via a bpx (int3)
# if post_<function> is defined, it is called whenever the function exists, with a bpx on the return address setup at func entry
# the pre_hook receives all arguments to the original function
#  change them with patch_arg(argnr, newval)
#  read memory with @dbg.memory_read_int(ptr), or @dbg.memory[ptr, length]
#  skip the function call with finish(fake_retval) (!) needs a correct :abi & param count !
# the post_hook receives the function return value
#  change it with patch_ret(newval)
class LibraryHook < ApiHook

	def setup
		@h_hash
	end

	def initialize(process, function_hash)
    @arguments = Array.new
		@h_hash = function_hash
		super(process)
	end

  def init_prerun
    puts "hooks ready, go for it!"
  end

  def get_arguments
    # Returns an array containing an Hash structure for every wrapped function
    @arguments
  end
end

EOS

functions.each do |function|

function_hook=<<EOS

  def pre_#{function}(handle, pbuf, size)
    # spy on the api / trace calls
    #bufdata = @dbg.memory[pbuf, size]
    tmp = read_arglist
    argomenti = tmp.slice(0..-3) # saltare gli ultimi due argomenti
    argomenti.each do |arg|
      addr = arg.to_s(16)
    end
    # Create an hash structure to insert all the infos about the wrapped function, for example name and an array with the arguments
    infos = Hash.new
    infos[:name] = "#{function}"
    infos[:args] = argomenti
    infos[:num] = argomenti.length
    @arguments << infos
  end
EOS
fixed_part = fixed_part + function_hook
end
f = File.open( output_file ,"w+")
f.puts( fixed_part )
return true
end #end generator

    def set_option_filename( filename = DEFAULT_OPTION_FILE )
      @option_filename = filename
    end

        # Il metodo apre il file contenente tutti i punti di interesse dello stato
        # # e cerca un match, restituendo un array con tutti i risultati del grep
        def file_grep( search_string )
          results = Array.new
          puts search_string if LOGLEVEL > 2

          File.open( @option_filename ) do |fh|
            fh.grep( /(.*)#{search_string}(.*)/ ) do |line|
              results << line
            end
          end
          results
        end

        def get_library_name

          raw_line = file_grep("LIB")
          line = raw_line.first.chomp
          pp raw_line if LOGLEVEL > 2

          name_array = line.split(/ /)   #LIB=<tab>library_name is the configuration schema
          puts name_array[1] if LOGLEVEL > 2
          return name_array[1] # the name is the 2nd element, the one after the token separator
        end

    def get_functions_list
      # Retrieves a list of functions to be wrapped by our code
      list = Array.new
      raw_list = file_grep("FUNCTION")
      raw_list.each do |line|
        line = line.chomp # removes trailing whitespace and '\n'
        name_array = line.split(/ /)
        list << name_array[1]
      end
      list
    end

    def get_params_from_process
      load @actual_output_file
      h_hash = [{ :function => 'ctest1'},{:function => 'ctest2'}]
      #h_hash = [{ :function => 'ctest2'}]
      # run our Hook engine on a running 'notepad' instance
      l = LibraryHook.new('prog', h_hash)
      argomenti = l.get_arguments #get infos about wrapped functions
      pp argomenti
      argomenti
    end

    def default_setup
      set_option_filename
      l = get_library_name
      f = get_functions_list
      return l, f
    end
  end
end
