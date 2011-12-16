require 'gsl/matrix'

module GSL
  module Matrix
    class Char < FFI::Struct
      include Functions
      include RealFunctions
    end
  end
end
