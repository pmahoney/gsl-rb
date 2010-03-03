require 'gsl/gsl'

module GSL

  class VectorStruct < FFI::Struct
    layout(:size, :size_t,
           :stride, :size_t,
           :data, :pointer,
           :block, :pointer,
           :owner, :int)
  end

  module Vector
    include GSL::Obj

    attr_reader :size

    METHOD_FREE ||= [:free, [:uintptr_t], :void]
    METHODS_STANDARD ||= [[:alloc, [:size_t], :pointer],
                          [:calloc, [:size_t], :pointer],

                          [:get, [:pointer, :size_t], :type],
                          [:set, [:pointer, :size_t, :type], :void],

                          [:ptr, [:pointer, :size_t], :pointer],
                          [:const_ptr, [:pointer, :size_t], :pointer],

                          [:set_all, [:pointer, :type], :void],
                          [:set_zero, [:pointer], :void],
                          [:set_basis, [:pointer, :size_t], :status],

                          [:memcpy, [:pointer, :pointer], :status],
                          [:swap, [:pointer, :pointer], :status],
                          [:swap_elements, [:pointer, :size_t, :size_t], :status],
                          [:reverse, [:pointer], :status],

                          [:add, [:pointer, :pointer], :status],
                          [:sub, [:pointer, :pointer], :status],
                          [:mul, [:pointer, :pointer], :status],
                          [:div, [:pointer, :pointer], :status],
                          [:scale, [:pointer, :double], :status],
                          [:add_constant, [:pointer, :double], :status]]

    # The following methods are not supported for complex types
    METHODS_REAL ||= [[:max, [:pointer], :type],
                      [:min, [:pointer], :type],
                      [:minmax, [:pointer, :pointer, :pointer], :void],
                      [:max_index, [:pointer], :size_t],
                      [:min_index, [:pointer], :size_t],
                      [:minmax_index, [:pointer, :pointer, :pointer], :void],

                      [:isnull, [:pointer], :int],
                      [:ispos, [:pointer], :int],
                      [:isneg, [:pointer], :int]]
                      # [:isnonneg, [:pointer], :int]  # function not on darwin?

    class << self
      # Convenience method that simply calls
      # GSL::Vector::Double.new().
      def new(*args)
        Vector::Double.new(*args)
      end

      def included(mod)
        mod.extend(GSL::Obj::Support)
        mod.extend(GSL::Obj::TypedSupport)
      end
    end

    # Create a new vector of the given size.  If 'size' is an
    # array-like object responding to #size and #each, then create a
    # vector initializing it to the size and values of the array-like
    # object.
    def initialize(arg)
      if (arg.respond_to? :size) && (arg.respond_to? :each)
        ary = arg
        size = arg.size
      else
        size = arg
      end

      @gsl = VectorStruct.new(alloc(size))

      @size = @gsl[:size]
      @stride = @gsl[:stride]

      # Optional initialization from array-like object
      if ary
        i = 0
        ary.each do |v|
          self[i] = v
          i += 1
        end
      end
    end

    def clone
      d = super()
      d.send(:initialize, size)
      _memcpy(d.gsl, self.gsl)
      d
    end

    # Get the element at the given index
    def [] (idx)
      _get(gsl, idx)
    end

    # Set the element and the given index to the given value.
    def []= (idx, val)
      _set(gsl, idx, val)
      self
    end

    # Set all elements to +value+.  Modifies +self+
    def set_all!(value)
      _set_all(gsl, value)
      self
    end

    # Set all elements to zero.  Modifies +self+.
    def set_zero!()
      _set_zero(gsl)
      self
    end

    # Returns a copy of the vectorwith all elements set to zero.
    def set_zero()
      clone.set_zero!
    end

    # Iterate through each value of the vector.
    def each
      size.times do |idx|
        yield(self[idx])
      end
    end

    # Iterate through each index of the vector.
    def each_index
      size.times do |idx|
        yield(idx)
      end
    end

    # Return a Ruby array containing the vector values.
    def to_ary
      ary = Array.new(size)
      each_index do |i|
        ary[i] = self[i]
      end
      return ary
    end

    # Add +other+ to self elementwise.
    def add!(other)
      check_matching_vector_arg(other)
      _add(gsl, other.gsl)
      self
    end

    def sub!(other)
      check_matching_vector_arg(other)
      _sub(gsl, other.gsl)
      self
    end

    def mul!(other)
      check_matching_vector_arg(other)
      _mul(gsl, other.gsl)
      self
    end

    def div!(other)
      check_matching_vector_arg(other)
      _div(gsl, other.gsl)
      self
    end

    def set_all(value)
      clone.set_all!(value)
    end

    def add(other)
      clone.add!(other)
    end

    def sub(other)
      clone.sub!(other)
    end

    def mul(other)
      clone.mul!(other)
    end

    def div(other)
      clone.div!(other)
    end

    # :nodoc:
    def self.check_matching_vector_arg(a, b)
      if !(b.kind_of? GSL::Vector)
        raise ArgumentError.new("not a vector")
      elsif !(b.kind_of? a.class)
        msg = "vector of class #{b.class} but require #{a.class}"
        raise ArgumentError.new(msg)
      end
    end

    # :nodoc:
    def check_matching_vector_arg(arg)
      Vector.check_matching_vector_arg(self, arg)
    end

    class Double
      include Vector

      gsl_methods(:vector, :double) do
        GSL::Vector::METHODS_STANDARD.each {|m| attach(*m)}
        GSL::Vector::METHODS_REAL.each {|m| attach(*m)}
        attach_class(*GSL::Vector::METHOD_FREE)
      end
    end

    class Int
      include Vector

      gsl_methods(:vector, :int) do
        GSL::Vector::METHODS_STANDARD.each {|m| attach(*m)}
        GSL::Vector::METHODS_REAL.each {|m| attach(*m)}
        attach_class(*GSL::Vector::METHOD_FREE)
      end
    end

    class Float
      include Vector

      gsl_methods(:vector, :float) do
        GSL::Vector::METHODS_STANDARD.each {|m| attach(*m)}
        GSL::Vector::METHODS_REAL.each {|m| attach(*m)}
        attach_class(*GSL::Vector::METHOD_FREE)
      end
    end

  end

end
