require 'gsl/matrix'

module GSL
  module Matrix
    class UInt < FFI::Struct
      include Functions
    end
  end
end
