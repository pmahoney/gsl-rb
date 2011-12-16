require 'gsl/matrix'

module GSL
  module Matrix
    class Long < FFI::Struct
      include Functions
    end
  end
end
