require 'gsl/matrix'

module GSL
  module Matrix
    class ULong < FFI::Struct
      include Functions
    end
  end
end
