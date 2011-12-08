require 'gsl/matrix'

module GSL
  class Matrix
    class UInt < FFI::Struct
      include MatrixFunctions
    end
  end
end
