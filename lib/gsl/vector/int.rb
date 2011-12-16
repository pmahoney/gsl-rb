require 'gsl/vector'

module GSL
  module Vector
    class Int < FFI::Struct
      include Functions
    end
  end
end
