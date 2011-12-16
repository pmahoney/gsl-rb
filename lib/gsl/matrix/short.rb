require 'gsl/matrix'

module GSL
  module Matrix
    class Short < FFI::Struct
      include Functions
      include RealFunctions
    end
  end
end
