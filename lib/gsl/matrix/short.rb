require 'gsl/matrix'

module GSL
  class Matrix
    class Short < FFI::Struct
      include MatrixFunctions
    end
  end
end
