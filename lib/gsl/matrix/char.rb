require 'gsl/matrix'

module GSL
  module Matrix
    class Char < FFI::Struct
      include Functions
    end
  end
end
