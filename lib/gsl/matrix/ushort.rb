require 'gsl/matrix'

module GSL
  module Matrix
    class UShort < FFI::Struct
      include Functions
      include RealFunctions
    end
  end
end
