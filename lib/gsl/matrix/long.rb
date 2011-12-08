require 'gsl/matrix'

module GSL
  class Matrix
    class Long < FFI::Struct
      include MatrixFunctions
    end
  end
end
