require 'gsl/matrix'

module GSL
  module Matrix
    class UInt < FFI::Struct
      include Functions
      include RealFunctions
    end
  end
end
