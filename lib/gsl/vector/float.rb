require 'gsl/vector'

module GSL
  module Vector
    class Float < FFI::Struct
      include Functions
    end
  end
end
