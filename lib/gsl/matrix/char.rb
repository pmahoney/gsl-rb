require 'gsl/matrix'

module GSL
  class Matrix
    class Char < FFI::Struct
      include MatrixFunctions
    end
  end
end
