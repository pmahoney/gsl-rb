require 'gsl/matrix'

module GSL
  class Matrix
    class Complex < FFI::Struct
      include MatrixFunctions
    end
  end
end
