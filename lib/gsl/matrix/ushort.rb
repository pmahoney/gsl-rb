require 'gsl/matrix'

module GSL
  class Matrix
    class UShort < FFI::Struct
      include MatrixFunctions
    end
  end
end
