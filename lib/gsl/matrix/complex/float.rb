require 'gsl/matrix'

module GSL
  class Matrix
    class Complex
      class Float < FFI::Struct
        include MatrixFunctions
      end
    end
  end
end
