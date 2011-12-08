require 'gsl/matrix'

module GSL
  class Matrix
    class Complex
      class LongDouble < FFI::Struct
        include MatrixFunctions
      end
    end
  end
end
