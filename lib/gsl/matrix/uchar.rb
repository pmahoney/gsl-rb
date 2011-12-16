require 'gsl/matrix'

module GSL
  module Matrix
    class UChar < FFI::Struct
      include Functions
      include RealFunctions
    end
  end
end
