require 'gsl/matrix'

module GSL
  module Matrix
    class Short < FFI::Struct
      include Functions
    end
  end
end
