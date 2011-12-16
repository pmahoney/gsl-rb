require 'gsl/vector'

module GSL
  module Vector
    class Short < FFI::Struct
      include Functions
    end
  end
end
