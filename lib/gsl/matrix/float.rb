require 'gsl/matrix'

module GSL
  class Matrix
    class Float < FFI::Struct
      include MatrixFunctions
    end
  end
end
