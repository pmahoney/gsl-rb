require 'gsl/vector'

module GSL
  module Vector
    class UShort < FFI::Struct
      include Functions
    end
  end
end
