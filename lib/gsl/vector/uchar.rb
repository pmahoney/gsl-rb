require 'gsl/vector'

module GSL
  module Vector
    class UChar < FFI::Struct
      include Functions
    end
  end
end
