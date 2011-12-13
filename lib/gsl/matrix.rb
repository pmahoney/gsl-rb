require 'gsl/gsl'

module GSL
  module MatrixFunctions
    def self.included(mod)
      mod.module_eval do
        extend Helper

        layout(:rows, :size_t,
               :cols, :size_t,
               :tda, :size_t,
               :data, :pointer,
               :block, :pointer,
               :owner, :int)

        matrix_type, scalar_type = gsl_types
        GSL.typedef :pointer, matrix_type

        # Note:
        # - within instance_eval, def creates class methods in mod
        # - within module_eval, def creates instance methods in mod
        #
        # We need free as both an instance and class method (for use by the finalizer)

        # Allocating matrices

        each_local_name('alloc', 'calloc') do
          attach_gsl_function([:size_t, :size_t], matrix_type)
          define_instance_upcall(:rows, :cols)
        end

        each_local_name('free') do
          attach_gsl_function([matrix_type], :void)
          define_instance_upcall(:ptr)
          define_module_upcall
        end

        # Initializing Matrix Elements

        each_local_name('set_zero', 'set_identity') do
          attach_gsl_function([matrix_type], :void)
          define_module_upcall!
        end

        each_local_name('set_all') do
          attach_gsl_function([matrix_type, scalar_type], :void)
          define_module_upcall!(:x)
        end

        # Accessing Matrix Elements

        each_local_name('get') do
          attach_gsl_function([matrix_type, :size_t, :size_t], scalar_type)
          define_module_upcall(:i, :j)
        end

        each_local_name('set') do
          attach_gsl_function([matrix_type, :size_t, :size_t, scalar_type], :void)
          define_module_upcall!(:i, :j, :x)
        end

        # Matrix Operations

        each_local_name('add', 'sub', 'mul_elements', 'div_elements') do
          attach_gsl_function([matrix_type, matrix_type], :void)
          define_module_upcall!(:other)
        end

        each_local_name('scale', 'add_constant') do
          attach_gsl_function([matrix_type, scalar_type], :void)
          define_module_upcall!(:arg)
        end
      end
    end

    def initialize(rows, cols, opts={})
      if opts[:zero]
        super(self.class.calloc(rows, cols))
      else
        super(self.class.alloc(rows, cols))
      end

      fin = self.class.make_finalizer(to_ptr.address)
      ObjectSpace.define_finalizer(self, fin)
    end
  end

  # Functions only defined on real matrices (as opposed to complex).
  module MatrixFunctionsReal
    def included(mod)
      mod.module_eval do
        matrix_type, scalar_type = gsl_types

        # Finding maximum and minimum elements of matrices

        each_local_name('max', 'min') do
          attach_gsl_function([matrix_type], scalar_type)
          define_module_upcall
        end
      end
    end
  end

  class Matrix < FFI::Struct
    include MatrixFunctions
  end
end
