module GSL

  extend FFI::Library
  ffi_lib 'libgslcblas.so.0', 'libgsl.so.0'

  class << self

    # Partial emulation of FFI's 'enum' support which is not in JRuby.
    # Defines a typedef to :int of the given type and stores a int
    # value to symbol hash based on the spec.
    def enum(type, spec)
      typedef :int, type

      enum = Hash.new
      enum_rev = Hash.new

      last_code = nil
      val = 0
      skip = false
      spec.each_index do |i|
        if (skip)
          skip = false
          next
        end

        if (spec[i].kind_of? Symbol) && (spec[i+1].kind_of? Fixnum)
          val = spec[i+1]
          code = spec[i]

          enum[code] = val
          enum_rev[val] = code

          skip = true
          val += 1
        elsif (spec[i].kind_of? Symbol)
          code = spec[i]

          enum[code] = val
          enum_rev[val] = code

          val += 1
        end
      end

      @@enum ||= Hash.new
      @@enum[type] = enum

      @@enum_rev ||= Hash.new
      @@enum_rev[type] = enum_rev
    end

    # Given an enum value, lookup the corresponding symbol.  Or, given
    # a symbol, lookup the corresponsing value.
    def enum_value(type, arg)
      if (arg.kind_of? Symbol)
        enum = @@enum[type]
        raise ArgumentError.new("no such enum #{type}") unless enum

        v = enum[arg]
        raise ArgumentError.new("not found #{type}[#{val}]") unless v
        v
      elsif (arg.kind_of? Fixnum)
        enum_rev = @@enum_rev[type]
        raise ArgumentError.new("no such enum #{type}") unless enum_rev

        v = enum_rev[arg]
        raise ArgumentError.new("not found #{type}[#{val}]") unless v
        v
      else
        msg ="expected symbol or integer but got #{arg.class}"
        raise ArgumentError.new(msg)
      end
    end

    # Most GSL functions operate over these types or objects based on
    # these types.
    def types()
      [:double, :float,
       # :long_double,
       :int, :uint, :long, :ulong,
       :short, :ushort, :char, :uchar,
       :complex, :complex_float,
       # :complex_long_double
      ]
    end

    # Just the real (non-complex) types
    def types_real()
      types.delete_if {|t| (t == :complex ||
                            t == :complex_float ||
                            t == :complex_long_double)}
    end

    # If type is :type, return default, else return type.
    def typeconv(type, default)
      if type == :type
        default
      else
        type
      end
    end

    # Create a method name following the GSL convention.  For example,
    # method_name(:gsl_vector, :int, :set) ->
    # :gsl_vector_int_set. Methods with type :double are the default
    # and thus do not have the type in the method name.  The type is
    # also left out if +type+ is nil.
    def method_name(base, type, suffix)
      if (type == nil) || (type == :double)
        (base.to_s + '_' + suffix.to_s).to_sym
      else
        (base.to_s + '_' + type.to_s + '_' + suffix.to_s).to_sym
      end
    end

    # Defines a method for all data types (double, float, long double,
    # int, uint, long, ulong, short, ushort, char, uchar, complex,
    # complex float, complex long double)
    def attach_type_functions(prefix, suffix, args, ret, types=GSL.types)
      types.each do |type|
        # map :type to the actualy type in use
        newargs = args.map {|v| typeconv(v, type)}
        newret = typeconv(ret, type)

        fname = method_name(prefix, type, suffix)
        attach_function(fname, newargs, newret)
      end
    end

    # Runs the block in a context that has an "attach" method that
    # will call attach_type_functions(prefix, suffix, args, ret)
    def attach_prefix_type_function(prefix, &block)
      mod = self
      attacher = Module.new
      attacher.send(:define_method, :attach) do |suffix, args, ret|
        mod.send(:attach_type_functions,
                 prefix, suffix, args, ret)
      end
      attacher.send(:module_function, :attach)

      attacher.send(:define_method, :attach_reals) do |suffix, args, ret|
        mod.send(:attach_type_functions,
                 prefix, suffix, args, ret, GSL.types_real)
      end
      attacher.send(:module_function, :attach_reals)

      attacher.module_eval(&block)
    end

  end

  # typedef :double :long_double
  # FIXME: these are incorrect
  typedef :double, :complex
  typedef :float, :complex_float
  # uintptr_t isn't defined on all platforms?
  typedef :ulong, :uintptr_t unless FFI::TypeDefs[:uintptr_t]

  enum :status, [:success, 0,
                 :failure, -1,
                 :continue, -2,
                 :edom, 1,
                 :erange,
                 :efault,
                 :einval,
                 :efailed,
                 :efactor,
                 :esanity,
                 :enomem,
                 :ebadfunc,
                 :erunaway,
                 :emaxiter,
                 :ezerodiv,
                 :ebadtol,
                 :etol,
                 :eunderflw,
                 :eovrflw,
                 :eloss,
                 :eround,
                 :ebadlen,
                 :enotsqr,
                 :esing,
                 :ediverge,
                 :eunsup,
                 :eunimpl,
                 :ecache,
                 :etable,
                 :enoprog,
                 :enoprogj,
                 :etolf,
                 :etolx,
                 :etolg,
                 :eof]

  enum :order, [:row_major, 101,
                :col_major, 102]
  enum :transpose, [:no_trans, 111,
                    :trans, 112,
                    :conjtrans, 113]
  enum :uplo, [:upper, 121,
               :lower, 122]
  enum :diag, [:non_unit, 131,
               :unit, 132]
  enum :side, [:left, 141,
               :right, 142]

  # Supporting methods for Vector, Matrix classes
  module Obj
    def self.included(mod)
      mod.extend(GSL::Obj::Support)
    end

    protected

    def type
      return @type
    end

    # Return the FFI pointer to the GSL object
    def gsl
      @gsl
    end

    def gsl=(g)
      @gsl = g
    end

    def alloc(*args)
      ptr = _alloc(*args)
      if ptr.null?
        raise GSL::Error:Failed.new('alloc failed for unknown reasons')
      end

      finalizer = GSL::Obj.finalize(self.class, ptr)
      ObjectSpace.define_finalizer(ptr, finalizer)

      ptr
    end

    # This needs to be a class method so that the proc does not retain
    # a reference to 'self' which would then never be garbage
    # collected (actually, JRuby seems to still collect it while
    # Ruby1.9 does not).
    #
    # Also, we store the address of the pointer so we do not keep a
    # reference to the pointer object itself.  Note that this requires
    # the function prototypes of the _free functions specify a
    # :uintptr_t rather than a :pointer.
    def self.finalize(klass, ptr)
      addr = ptr.address
      proc do |id|
        klass._free(addr)
      end
    end

    # These methods are installed via extend into the Vector and
    # Matrix classes (or any class that includes the GSL::Obj module.
    module Support
      def prefix(p)
        @prefix = p
      end

      def gsl_method_name(name)
        GSL.method_name(@prefix, @type, name)
      end

      def foreign_method(*args)
        @foreign_methods ||= []
        args.each do |m|
          @foreign_methods << m
        end
      end

      # Define the foreign method hash according to +type+.
      def define_foreign_methods(*args)
        type = args[0]          #  can be nil
        @type = type
        @foreign_methods.each do |suffix|
          gsl_method = gsl_method_name(suffix)
          local_method = ('_' + suffix.to_s).to_sym
          define_method(local_method) do |*args|
            GSL.send(gsl_method, *args)
          end
          protected(local_method)
        end
      end

    end
  end

end
