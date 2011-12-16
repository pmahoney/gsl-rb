require 'gsl/matrix'

module GSL
  module Matrix
    class Double < FFI::Struct
      include Functions
      include RealFunctions
    end
  end
end
