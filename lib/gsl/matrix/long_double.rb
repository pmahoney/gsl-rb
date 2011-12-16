require 'gsl/matrix'

module GSL
  module Matrix
    class LongDouble < FFI::Struct
      include Functions
    end
  end
end
