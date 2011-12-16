require 'gsl/vector'

module GSL
  module Vector
    class Double < FFI::Struct
      include Functions
    end
  end
end
