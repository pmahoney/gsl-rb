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

    def attach_gsl_function(*local_names)
      local_names.each do |local_name|
        f = FunctionSpec.new(local_name, gsl_name(local_name))
        # block must set f.signature, f.type
        yield f
        GSL.attach_function(f.gsl_name, *f.signature)
      end
    end

    def argstring(args)
      args.map { |a| a.to_s }.join(', ')
    end

    # Create a string that defines a method named
    # `f.local_name` that simply calls GSL.`f.gsl_name`.
    #
    # @param [FunctionSpec] f
    # @param [Array] non_self_args array of string arg names
    def upcall(f, non_self_args = [], opts = {})
      decl_args = argstring(non_self_args)
      body_args = unless opts[:no_self]
                    argstring(['self'] + non_self_args)
                  else
                    decl_args
                  end

      local_name = if opts[:destructive]
                     f.local_name + '!'
                   else
                     f.local_name
                   end

      gsl_name = "GSL.#{f.gsl_name}"
      
      %Q{
        def #{local_name}(#{decl_args})
          #{gsl_name}(#{body_args})
        end
      }
    end

    # Define a method at the instance level of self (a class method)
    # that simply calls a GSL function.
    def define_instance_upcall(f, args = [])
      instance_eval upcall(f, args, :no_self => true)
    end

    # Define a method at the module level of self (would become an
    # instance method) that simply calls a GSL function.
    def define_module_upcall(f, args = [])
      module_eval upcall(f, args)
    end

    # Define a destructive method ('!' is appended to the local method
    # name) at the module level of self (would become an instance
    # method) that simply calls a GSL function.
    def define_module_upcall!(f, args = [])
      module_eval upcall(f, args, :destructive => true)
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

        # Note: within instance_eval, def creates class methods in mod

        attach_gsl_function('alloc', 'calloc') do |f|
          f.signature [:size_t, :size_t], matrix_type
          #instance_eval upcall(f, %w[rows cols], :no_self => true)
          define_instance_upcall(f, %w[rows cols])
        end

        attach_gsl_function('free') do |f|
          f.signature [matrix_type], :void
          define_instance_upcall(f, %w[ptr])
        end

        # Note: within module_eval, def creates instance methods in mod

        # Free

        attach_gsl_function('free') do |f|
          f.signature [matrix_type], :void
          define_module_upcall(f)
        end

        # Accessing Matrix Elements

        attach_gsl_function('get') do |f|
          f.signature [matrix_type, :size_t, :size_t], :void
          define_module_upcall(f, %w[i j])
        end

        attach_gsl_function('set') do |f|
          f.signature [matrix_type, :size_t, :size_t, scalar_type], :void
          define_module_upcall!(f, %w[i j x])
        end

        # Matrix Operations

        attach_gsl_function('add', 'sub', 'mul_elements', 'div_elements') do |f|
          f.signature [matrix_type, matrix_type], :void
          define_module_upcall!(f, %w[other])
        end

        attach_gsl_function('scale', 'add_constant') do |f|
          f.signature [matrix_type, scalar_type], :void
          define_module_upcall!(f, %w[arg])
        end

        # Finding maximum and minimum elements of matrices

        # attach_gsl_function('max', 'min') do |f|
        #   f.signature [matrix_type], scalar_type
        #   module_eval %Q{
        #     def #{f.local_name}
        #       GSL.#{f.gsl_name}(self)
        #     end
        #   }
        # end
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

  class Matrix < FFI::Struct
    include MatrixFunctions
  end
end
