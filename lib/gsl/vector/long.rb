require 'gsl/vector'

module GSL
  module Vector
    class Long < FFI::Struct
      include Functions
    end
  end
end
