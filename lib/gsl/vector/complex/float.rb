require 'gsl/vector'

module GSL
  module Vector
    class Complex
      class Float < FFI::Struct
        include Functions
      end
    end
  end
end
