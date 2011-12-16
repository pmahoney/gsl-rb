require 'gsl/matrix'

module GSL
  module Matrix
    class ULong < FFI::Struct
      include Functions
      include RealFunctions
    end
  end
end
