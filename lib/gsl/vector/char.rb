require 'gsl/vector'

module GSL
  module Vector
    class Char < FFI::Struct
      include Functions
    end
  end
end
