require 'gsl/matrix'

module GSL
  module Matrix
    class UShort < FFI::Struct
      include Functions
    end
  end
end
