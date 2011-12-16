require 'gsl/matrix'

module GSL
  module Matrix
    class Complex < FFI::Struct
      include Functions
    end
  end
end
