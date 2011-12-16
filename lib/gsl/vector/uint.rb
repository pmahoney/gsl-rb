require 'gsl/vector'

module GSL
  module Vector
    class UInt < FFI::Struct
      include Functions
    end
  end
end
