require 'gsl/matrix'

module GSL
  module Matrix
    class Complex
      class Float < FFI::Struct
        include Functions
      end
    end
  end
end
