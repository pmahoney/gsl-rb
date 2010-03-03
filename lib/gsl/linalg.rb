# Linear Algebra routines.  Requiring this module adds linear algebra
# methods to Matrix and Vector classes.

require 'gsl'
require 'gsl/permutation'

module GSL

  attach_function(:gsl_linalg_LU_decomp,
                  [:pointer, :pointer, :pointer],
                  :int)

  attach_function(:gsl_linalg_LU_solve,
                  [:pointer, :pointer, :pointer, :pointer],
                  :int)

  attach_function(:gsl_linalg_LU_invert,
                  [:pointer, :pointer, :pointer],
                  :int)

  class IntStruct < FFI::Struct
    layout(:value, :int)
  end

  module Matrix

    module LinAlg
      # Mutate the matrix into its LU decomposition and add methods
      # that operate on the LU decomposition such as #solve and
      # #inv.
      def LU_decomp!
        p = GSL::Permutation.new(self.cols)
        signum = IntStruct.new()
        _LU_decomp!(p, signum)

        @is_LU_decomp = true
        @perm = p
        @signum = signum[:value]

        class << self
          include LU_Decomp
        end

        self
      end

      # Methods that are available to a matrix that is an LU
      # decomposition.
      module LU_Decomp
          attr_reader :perm, :signum

          # Returns true if +self+ is an LU decomposition matrix
          # created as a result of Matrix#LU_decomp!
          def is_LU_decomp?
            return @is_LU_decomp
          end

          # Solve the system for +vec+.
          #
          # This method will be added to the Matrix module after
          # Matrix#LU_decomp! and thus only available from a matrix
          # that is an LU decomposition.
          def solve(vec)
            _LU_solve(perm, vec)
          end

          # Compute the inverse of the matrix from its LU
          # decomposition.
          #
          # Note (from GSL documentation): "It is preferable to avoid
          # direct use of the inverse whenever possible, as the linear
          # solver functions can obtain the same result more
          # efficiently and reliably"
          #
          # This method will be added to the Matrix module after
          # Matrix#LU_decomp! and thus only available from a matrix
          # that is an LU decomposition.
          def inv()
            _LU_invert(perm)
          end
      end

      # :nodoc: all
      module Double
        include LinAlg

        def _LU_decomp!(p, signum)
          GSL.gsl_linalg_LU_decomp(self.gsl, p.gsl, signum.to_ptr)
        end

        def _LU_solve(perm, vec)
          result = GSL::Vector::Double.new(vec.size)
          GSL.gsl_linalg_LU_solve(self.gsl, perm.gsl,
                                  vec.gsl, result.gsl)
          result
        end

        def _LU_invert(perm)
          inv = GSL::Matrix::Double.new(rows,cols)
          GSL.gsl_linalg_LU_invert(self.gsl, perm.gsl, inv.gsl)
          inv
        end
      end
    end

  end

  class Matrix::Double
    include Matrix::LinAlg::Double
  end

end
