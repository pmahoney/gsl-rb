require 'gsl/matrix'

module GSL
  module Matrix
    class Int < FFI::Struct
      include Functions
      include RealFunctions
    end
  end
end
