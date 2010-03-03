require 'gsl'

module GSL

  class PermutationStruct < FFI::Struct
    layout(:size, :size_t,
           :data, :pointer)
  end

  class Permutation
    include GSL::Obj

    gsl_methods(:permutation) do
      attach :alloc, [:size_t], :pointer
      attach :calloc, [:size_t], :pointer
      attach_class :free, [:uintptr_t], :void
    end

    def initialize(size)
      @gsl = alloc(size)
    end

  end
end
