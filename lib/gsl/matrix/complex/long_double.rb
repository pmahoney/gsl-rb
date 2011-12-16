require 'gsl/matrix'

module GSL
  module Matrix
    class Complex
      class LongDouble < FFI::Struct
        include Functions
      end
    end
  end
end
