require 'gsl/matrix'

module GSL
  class Matrix
    class Int < FFI::Struct
      include MatrixFunctions
    end
  end
end
