module GSL

  extend FFI::Library
  begin
    ffi_lib 'libgslcblas', 'libgsl'
  rescue LoadError
    # My ubuntu karmic doesn't have libgsl.so, so FFI fails; must
    # explicitly try libgsl.so.0.
    ffi_lib 'libgslcblas.so.0', 'libgsl.so.0'
  end

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

      # :nodoc:
      def gsl_method(local_method, gsl_function)
        define_method(local_method) do |*args|
          GSL.send(gsl_function, *args)
        end
      end
      private :gsl_method

      # :nodoc:
      def gsl_class_method(local_method, gsl_function)
        klass = (class << self; self; end)
        klass.instance_eval do
          define_method(local_method) do |*args|
            GSL.send(gsl_function, *args)
          end
        end
      end
      private :gsl_class_method

      # Execute the block in a module context that has two methods:
      # 'attach' and 'attach_class'.
      def gsl_methods(prefix, &block)
        attacher = Attacher.new(prefix, self)
        attacher.instance_eval(&block)
      end

    end

    module TypedSupport
      def gsl_methods(prefix, type, &block)
        attacher = TypedAttacher.new(prefix, type, self)
        attacher.instance_eval(&block)
      end
    end
  end

  # Helper class for attaching gsl functions to the GSL module as well
  # as to a local class.  Attaches the FFI function to the GSL module.
  # Attaches a local +_suffix()+ method to the local class that calls
  # the method defined in the GSL module.
  class Attacher
    attr_reader :prefix, :local_class

    # Attach gsl functions with prefix +prefix+ to +local_class+.
    def initialize(prefix, local_class)
      @prefix = prefix
      @local_class = local_class
    end

    # Attach a function with the given +suffix+, function signature
    # +sig+, and return value +ret+. See FFI::Library#attach_function.
    #
    # The local method will be attached as an instance method.
    def attach(suffix, sig, ret)
      attach_gsl_method(:gsl_method, suffix, sig, ret)
    end

    # Attach a function with the given +suffix+, function signature
    # +sig+, and return value +ret+. See FFI::Library#attach_function.
    #
    # The local method will be attached as a class method.
    def attach_class(suffix, sig, ret)
      attach_gsl_method(:gsl_class_method, suffix, sig, ret)
    end

    private

    def attach_gsl_method(location, suffix, sig, ret)
      func = gsl_function(suffix)
      meth = local_method(suffix)

      GSL.attach_function(func, sig, ret)
      local_class.send(location, meth, func)
    end

    def gsl_function(suffix)
      ['gsl', prefix.to_s, suffix.to_s].join('_').to_sym
    end

    def local_method(suffix)
      ('_' + suffix.to_s).to_sym
    end
  end

  class TypedAttacher < Attacher
    attr_reader :type

    def initialize(prefix, type, local_class)
      super(prefix, local_class)
      @type = type
    end

    private

    def typeconv(atype)
      if atype == :type
        type
      else
        atype
      end
    end

    def attach_gsl_method(location, suffix, sig, ret)
      newsig = sig.map{|t| typeconv(t)}
      newret = typeconv(ret)
      super(location, suffix, newsig, newret)
    end

    def gsl_function(suffix)
      if type == :double
        super(suffix)
      else
        ['gsl', prefix.to_s, type.to_s, suffix.to_s].join('_').to_sym
      end
    end
  end

end


