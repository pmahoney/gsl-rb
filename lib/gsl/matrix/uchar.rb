require 'gsl/matrix'

module GSL
  class Matrix
    class UChar < FFI::Struct
      include MatrixFunctions
    end
  end
end
