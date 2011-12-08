require 'gsl/matrix'

module GSL
  class Matrix
    class ULong < FFI::Struct
      include MatrixFunctions
    end
  end
end
