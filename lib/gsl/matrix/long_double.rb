require 'gsl/matrix'

module GSL
  class Matrix
    class LongDouble < FFI::Struct
      include MatrixFunctions
    end
  end
end
