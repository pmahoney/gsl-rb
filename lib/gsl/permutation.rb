require 'gsl'

module GSL

  attach_function :gsl_permutation_alloc, [:size_t], :pointer
  attach_function :gsl_permutation_calloc, [:size_t], :pointer
  attach_function :gsl_permutation_free, [:uintptr_t], :void

  class PermutationStruct < FFI::Struct
    layout(:size, :size_t,
           :data, :pointer)
  end

  class Permutation
    include GSL::Obj

    prefix :gsl_permutation
    foreign_method :alloc, :free
    define_foreign_methods

    def initialize(size)
      @gsl = alloc(size)
    end

    def self._free(ptr)
      GSL.gsl_permutation_free(ptr)
    end
  end
end
