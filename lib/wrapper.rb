require 'bombshell'
require 'interceptor'

module Wrapper
  class Shell < Bombshell::Environment
    include Bombshell::Shell
    prompt_with 'wrapperbot'

    def interceptor
      Interceptor.launch
    end
  end
end
