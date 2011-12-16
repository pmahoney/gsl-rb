require 'gsl/vector'

module GSL
  module Vector
    class ULong < FFI::Struct
      include Functions
    end
  end
end
