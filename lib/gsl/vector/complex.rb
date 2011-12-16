require 'gsl/vector'

module GSL
  module Vector
    class Complex < FFI::Struct
      include Functions
    end
  end
end
