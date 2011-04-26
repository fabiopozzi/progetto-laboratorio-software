require 'bombshell'
require 'interceptor'
require 'generator'

module Wrapper
  class Shell < Bombshell::Environment
    include Bombshell::Shell
    prompt_with 'wrapperbot'

    def generator 
      Generator.launch
    end

    def interceptor
      Interceptor.launch
    end
  end
end
