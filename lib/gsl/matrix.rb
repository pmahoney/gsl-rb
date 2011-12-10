require 'gsl/gsl'

module GSL
  class FunctionSpec
    attr_reader :gsl_name, :local_name

    def initialize(local_name, gsl_name)
      @local_name = local_name
      @gsl_name = gsl_name
    end

    # getter and setter combined
    def signature(*sig)
      if sig.size > 0
        @signature = sig
      else
        @signature
      end
    end
  end

  class AttachDsl
    attr_reader :mod, :local_name, :gsl_name

    def initialize(mod, local_name, gsl_name)
      @mod = mod
      @local_name = local_name
      @gsl_name = gsl_name
    end

    def attach_gsl_function(*args)
      GSL.attach_function(gsl_name, *args)
    end

    def define_instance_upcall(*args)
      mod.define_instance_upcall(local_name, gsl_name, args)
    end

    def define_module_upcall(*args)
      mod.define_module_upcall(local_name, gsl_name, args)
    end

    def define_module_upcall!(*args)
      mod.define_module_upcall!(local_name, gsl_name, args)
    end
  end

  module Helpers
    def underscore(camel_case_word)
      camel_case_word.to_s.gsub(/::/, '_').
#        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

    def make_finalizer(addr)
      proc { free(FFI::Pointer.new(addr)) }
    end

    # When inside GSL::Matrix::Float, when name is 'alloc',
    # returns 'gsl_matrix_float_alloc'.
    def gsl_name(name)
      underscore(self.to_s + '_' + name)
    end

    # When inside GSL::Matrix::Float,returns `[:gsl_matrix_float, :float]`
    def gsl_types
      scalar_type = case t = underscore(self.to_s.split('::')[-1]).to_sym
                    when :char, :complex, :float, :int, :long_double,
                      :long, :short, :uchar, :uint, :ulong, :ushort
                      t
                    else
                      :double
                    end
      [underscore(self).to_sym, scalar_type]
    end

    def each_local_name(*local_names, &block)
      local_names.each do |local_name|
        dsl = AttachDsl.new(self, local_name, gsl_name(local_name))
        dsl.instance_eval &block
      end
    end

    def argstring(args)
      args.map { |a| a.to_s }.join(', ')
    end

    # Create a string that defines a method named
    # `local_name` that simply calls GSL.`gsl_name`.
    #
    # @param [String|Symbol] local_name
    # @param [String|Symbol] gsl_name
    # @param [Array] non_self_args array of string arg names
    # @param [Hash] opts
    def upcall(local_name, gsl_name, non_self_args = [], opts = {})
      decl_args = argstring(non_self_args)
      body_args = unless opts[:no_self]
                    argstring(['self'] + non_self_args)
                  else
                    decl_args
                  end

      local_name2 = if opts[:destructive]
                      local_name + '!'
                    else
                      local_name
                    end

      %Q{
        def #{local_name2}(#{decl_args})
          GSL.#{gsl_name}(#{body_args})
        end
      }
    end

    # Define a method at the instance level of self (a class method)
    # that simply calls a GSL function.
    def define_instance_upcall(local_name, gsl_name, args = [])
      instance_eval upcall(local_name, gsl_name, args, :no_self => true)
    end

    # Define a method at the module level of self (would become an
    # instance method) that simply calls a GSL function.
    def define_module_upcall(local_name, gsl_name, args = [])
      module_eval upcall(local_name, gsl_name, args)
    end

    # Define a destructive method ('!' is appended to the local method
    # name) at the module level of self (would become an instance
    # method) that simply calls a GSL function.
    def define_module_upcall!(local_name, gsl_name, args = [])
      module_eval upcall(local_name, gsl_name, args, :destructive => true)
    end
  end

  module MatrixFunctions
    def self.included(mod)
      mod.module_eval do
        extend Helpers

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
