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
          instance_eval %Q{
            def #{f.local_name}(rows, cols)
              GSL.#{f.gsl_name}(rows, cols)
            end
          }
        end

        attach_gsl_function('free') do |f|
          f.signature [matrix_type], :void
          instance_eval %Q{
            def #{f.local_name}(ptr)
              GSL.#{f.gsl_name}(ptr)
            end
          }
        end

        # Note: within module_eval, def creates instance methods in mod

        attach_gsl_function('get') do |f|
          f.signature [matrix_type, :size_t, :size_t], :void
          module_eval %Q{
            def #{f.local_name}(i, j)
              GSL.#{f.gsl_name}(self, i, j)
            end
          }
        end

        attach_gsl_function('set') do |f|
          f.signature [matrix_type, :size_t, :size_t, scalar_type], :void
          module_eval %Q{
            def #{f.local_name}!(i, j, x)
              GSL.#{f.gsl_name}(self, i, j, x)
            end
          }
        end

        attach_gsl_function('add', 'sub', 'mul_elements', 'div_elements') do |f|
          f.signature [matrix_type, matrix_type], :void
          module_eval %Q{
            def #{f.local_name}!(other)
              GSL.#{f.gsl_name}(self, other)
            end
          }
        end

        attach_gsl_function('scale', 'add_constant') do |f|
          f.signature [matrix_type, scalar_type], :void
          module_eval %Q{
            def #{f.local_name}!(arg)
              GSL.#{f.gsl_name}(self, arg)
            end
          }
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

    # Generally this should never be called.  The memory is freed in
    # an object finalizer.
    def free
      self.class.free(self)
    end

    def addblargh(other)
      self.class.add(self, other)
    end
  end

  class Matrix < FFI::Struct
    include MatrixFunctions
  end
end
