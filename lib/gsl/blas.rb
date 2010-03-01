# Basic Linear Algebra Subprograms

require 'gsl'

module GSL
  #------------------------------------------------------------
  # Level 1 BLAS - Vector-Vector
  #------------------------------------------------------------
  attach_function :gsl_blas_ddot, [:pointer, :pointer, :pointer], :int
  attach_function :gsl_blas_dsdot, [:pointer, :pointer, :pointer], :int

  attach_function :gsl_blas_snrm2, [:pointer], :float
  attach_function :gsl_blas_dnrm2, [:pointer], :double

  attach_function :gsl_blas_sasum, [:pointer], :float
  attach_function :gsl_blas_dasum, [:pointer], :double

  #------------------------------------------------------------
  # Level 2 BLAS - Matrix-Vector
  #------------------------------------------------------------
  attach_function(:gsl_blas_sgemv,
                  [:transpose, :double, :pointer, :pointer,
                   :double, :pointer],
                  :int)
  attach_function(:gsl_blas_dgemv,
                  [:transpose, :double, :pointer, :pointer,
                   :double, :pointer],
                  :int)

  #------------------------------------------------------------
  # Level 3 BLAS - Matrix-Matrix
  #------------------------------------------------------------
  attach_function(:gsl_blas_sgemm,
                  [:transpose, :transpose, :double, :pointer, :pointer,
                   :double, :pointer],
                  :int)
  attach_function(:gsl_blas_dgemm,
                  [:transpose, :transpose, :double, :pointer, :pointer,
                   :double, :pointer],
                  :int)

  # :nodoc:
  class DoubleStruct < FFI::Struct
    layout(:value, :double)
  end

  # :nodoc:
  class FloatStruct < FFI::Struct
    layout(:value, :double)
  end

  module Vector

    # Do <code>require 'gsl/blas'</code> and the BLAS methods will be
    # added to the GSL::Vector class.
    module BLAS
      # Compute the dot or scalar product of +self+ with +other+.
      # Vectors must be of the same underlying c-type and of the same
      # size.
      def dot(other)
        Vector.check_matching_vector_arg(self, other)
        _dot(other)
      end

      # Compute the Euclidian normal or vector magnitude.
      def magnitude()
        _nrm2()
      end
      alias_method :nrm2, :magnitude

      # Compute the absolute sum or sum of the absolute value of each
      # member.
      def asum()
        _asum()
      end

      # :nodoc:
      module Float
        include BLAS

        def _dot(other)
          result = DoubleStruct.new
          GSL.gsl_blas_dsdot(self.gsl, other.gsl, result.to_ptr)
          result[:value]
        end

        def _nrm2()
          GSL.gsl_blas_snrm2(self.gsl)
        end

        def _asum()
          GSL.gsl_blas_sasum(self.gsl)
        end
      end

      # :nodoc:
      module Double
        include BLAS

        def _dot(other)
          result = DoubleStruct.new
          GSL.gsl_blas_ddot(self.gsl, other.gsl, result.to_ptr)
          result[:value]
        end

        def _nrm2()
          GSL.gsl_blas_dnrm2(self.gsl)
        end

        def _asum()
          GSL.gsl_blas_dasum(self.gsl)
        end
      end

      # :nodoc:
      module Complex
      end

      # :nodoc:
      module ComplexFloat
      end
    end
  end

  module Matrix

    # Do <code>require 'gsl/blas'</code> and the BLAS methods will be
    # added to the GSL::Matrix class.  The methods are only available
    # for matricies of type +double+ and +float+.
    module BLAS

      # Multiply the matrix by +other+ which can be a vector or
      # another matrix.
      def mul(other)
        if (other.kind_of? GSL::Matrix)
          mulm(other)
        elsif (other.kind_of? GSL::Vector)
          mulv(other)
        else
          msg = "don't know how to multiply by #{other.class}"
          raise ArgumentError.new(msg)
        end
      end

      #------------------------------------------------------------
      # Level 2 BLAS - Matrix-Vector
      #------------------------------------------------------------

      # Multiply the matrix by the vector +other+ which must be of the
      # same type and have a size equal to the columns of the matrix.
      def mulv(other)
          unless (other.kind_of? GSL::Vector::Double)
            msg = "vector is #{other.class} but require #{GSL::Vector::Double}"
            raise ArgumentError.new(msg)
          end

        _mulv(other)
      end

      #------------------------------------------------------------
      # Level 3 BLAS - Matrix-Matrix
      #------------------------------------------------------------

      # Multiply the matrix by the matrix +other+ which must have rows
      # equal to the number of columns in +self+.
      def mulm(other)
        mulm_full(:no_trans, :no_trans, other)
      end

      # Multiply the transpose of +self+ with +other+.
      def trans_mul(other)
        mulm_full(:trans, :no_trans, other)
      end

      # Multiply +self+ with the transpose of +other+.
      def mul_trans(other)
        mulm_full(:no_trans, :trans, other)
      end

      # Multiply the transpose of +self+ with the transpose of +other+.
      def trans_mul_trans(other)
        mulm_full(:trans, :trans, other)
      end

      # FIXME: this only applies to matricies of complex values.
      # def conjugate_transpose()
      #   _transpose(GSL.enum_value(:transpose, :conjtrans))
      # end

      private

      def mulm_full(transA, transB, other)
        unless (other.kind_of? GSL::Matrix::Double)
          msg = "vector is #{other.class} but require #{GSL::Matrix::Double}"
          raise ArgumentError.new(msg)
        end

        _mulm(transA, transB, other)
      end

      #------------------------------------------------------------
      # Type specific implementations
      #------------------------------------------------------------

      # :nodoc: all
      module Double
        include BLAS

        def _mulv(other)
          result = GSL::Vector.new(self.rows)

          trans = GSL.enum_value(:transpose, :no_trans)
          GSL.gsl_blas_dgemv(trans, 1, self.gsl, other.gsl, 0, result.gsl)
          result
        end

        def _mulm(transA, transB, other)
          if transA == :no_trans
            rrows = self.rows
          else
            rrows = self.cols
          end

          if transB == :no_trans
            rcols = other.cols
          else
            rcols = other.rows
          end

          result = GSL::Matrix.new(rrows, rcols)

          ta = GSL.enum_value(:transpose, transA)
          tb = GSL.enum_value(:transpose, transB)
          GSL.gsl_blas_dgemm(ta, tb, 1, self.gsl, other.gsl, 0, result.gsl)
          result
        end
      end

      # :nodoc: all
      module Float
        include BLAS

        def _mulv(other)
          result = GSL::Vector::Float.new(self.rows)

          trans = GSL.enum_value(:transpose, :no_trans)
          GSL.gsl_blas_sgemv(trans, 1, self.gsl, other.gsl, 0, result.gsl)
          result
        end

        def _mulm(other)
          result = GSL::Matrix::Float.new(self.rows, other.cols)

          trans = GSL.enum_value(:transpose, :no_trans)
          GSL.gsl_blas_sgemm(trans, trans,
                             1, self.gsl, other.gsl, 0, result.gsl)
          result
        end
      end

    end
  end

  class Vector::Double
    include Vector::BLAS::Double
  end

  class Vector::Float
    include Vector::BLAS::Float
  end

  class Matrix::Double
    include Matrix::BLAS::Double
  end

  class Matrix::Float
    include Matrix::BLAS::Float
  end

end
