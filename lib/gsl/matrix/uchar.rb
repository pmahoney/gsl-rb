require 'gsl/matrix'

module GSL
  module Matrix
    class UChar < FFI::Struct
      include Functions
    end
  end
end
