require 'gsl/matrix'

module GSL
  module Matrix
    class Float < FFI::Struct
      include Functions
    end
  end
end
