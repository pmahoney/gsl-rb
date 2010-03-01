require 'gsl/gsl'

module GSL

  attach_prefix_type_function(:gsl_matrix) do
    attach :alloc, [:size_t, :size_t], :pointer
    attach :calloc, [:size_t, :size_t], :pointer
    attach :free, [:pointer], :void

    attach :get, [:pointer, :size_t, :size_t], :type
    attach :set, [:pointer, :size_t, :size_t, :type], :void
    attach :ptr, [:pointer, :size_t, :size_t], :pointer
    attach :const_ptr, [:pointer, :size_t, :size_t], :pointer

    attach :set_all, [:pointer, :type], :void
    attach :set_zero, [:pointer], :void
    attach :set_identity, [:pointer], :void

    # TODO?: read/write to files
    # attach :fwrite, [:pointer, :pointer], :int
    # attach :fread, [:pointer, :pointer], :int
    # attach :fprintf, [:pointer, :pointer, :string], :int
    # attach :fscanf, [:pointer, :pointer]

    # TODO: views

    # TODO: row and column views

    attach :memcpy, [:pointer, :pointer], :int
    attach :swap, [:pointer, :pointer], :int

    attach :get_row, [:pointer, :pointer, :size_t], :int
    attach :get_col, [:pointer, :pointer, :size_t], :int
    attach :set_row, [:pointer, :size_t, :pointer], :int
    attach :set_col, [:pointer, :size_t, :pointer], :int

    attach :swap_rows, [:pointer, :size_t, :size_t], :int
    attach :swap_columns, [:pointer, :size_t, :size_t], :int
    attach :swap_rowcol, [:pointer, :size_t, :size_t], :int
    attach :transpose_memcpy, [:pointer, :pointer], :int
    attach :transpose, [:pointer], :int

    attach :add, [:pointer, :pointer], :int
    attach :sub, [:pointer, :pointer], :int
    attach :mul_elements, [:pointer, :pointer], :int
    attach :div_elements, [:pointer, :pointer], :int
    attach :scale, [:pointer, :pointer], :int
    attach :add_constant, [:pointer, :pointer], :int
  end

  class MatrixStruct < FFI::Struct
    layout(:rows, :size_t,
           :cols, :size_t,
           :tda, :size_t,
           :data, :pointer,
           :block, :pointer,
           :owner, :int)
  end

  module Matrix
    include GSL::Obj

    attr_reader :size

    class << self
      # Convenience method that simply calls
      # GSL::Vector::Double.new().
      def new(*args)
        GSL::Matrix::Double.new(*args)
      end

      def included(mod)
        mod.extend(GSL::Obj::Support)
        mod.prefix :gsl_matrix
        mod.foreign_method(:alloc,
                           :calloc,
                           :free,
                           :get,
                           :set,
                           :ptr,
                           :const_ptr,
                           :set_all,
                           :set_zero,
                           :set_identity,
                           :memcpy,
                           :swap,
                           :get_row,
                           :get_col,
                           :set_row,
                           :set_col,
                           :swap_rows,
                           :swap_columns,
                           :swap_rowcol,
                           :transpose_memcpy,
                           :transpose,
                           :add,
                           :sub,
                           :mul_elements,
                           :div_elements,
                           :scale,
                           :add_constant)
      end
    end

    # Create a new matrix.
    def initialize(*args)
      if args.size == 2 # no array initializer
        rows = args[0]
        cols = args[1]
      elsif args.size == 3 # flat array initializer
        rows = args[0]
        cols = args[1]
        ary = args[2]
      elsif args.size == 1 # nested list (by rows) initializer
        rows = args[0].size
        cols = args[0][0].size
        ary = args[0]
      else
        raise ArgumentError.new("wrong args: #{args.size} for 1, 2, or 3")
      end

      @gsl = alloc(rows, cols)

      @size = [@gsl[:rows], @gsl[:cols]]

      if (args.size == 3) # flat array of value
        row = 0
        col = 0
        ary.each do |v|
          self[row, col] = v
          col += 1
          if (col == cols)
            col = 0
            row += 1
          end
        end
      elsif (args.size == 1) # nested array of rows of values
        row = 0
        ary.each do |rowdata|
          col = 0
          rowdata.each do |v|
            self[row, col] = v
            col += 1
          end
          row += 1
        end
      end
    end

    def alloc(rows, cols)
      g = MatrixStruct.new(_alloc(rows, cols))
      ObjectSpace.define_finalizer(g, proc {|id| _free(g)})
      g
    end
    private :alloc

    # Create a copy of the matrix.
    def dup
      d = super()
      d.gsl = alloc(rows, cols)
      _memcpy(d.gsl, @gsl)
      d
    end

    # Number or rows.
    def rows()
      size[0]
    end

    # Number of columns
    def cols()
      size[1]
    end

    def each_index
      rows.times do |row|
        cols.times do |col|
          yield(row, col)
        end
      end
    end

    def each_index_by_cols
      cols.times do |col|
        rows.times do |row|
          yield(row, col)
        end
      end
    end

    # Return a flat Ruby array containing the values ordered by rows.
    def to_ary
      ary = Array.new
      each_index do |row, col|
        ary << self[row,col]
      end
      ary
    end

    # Return a nested Ruby array by rows.
    def to_ary_rows
      ary = Array.new
      rowa = Array.new
      rowi = 0
      each_index do |row, col|
        if rowi != row
          rowi = row
          ary << rowa
          rowa = Array.new
        end

        rowa << self[row, col]
      end

      ary << rowa
      ary
    end

    # Return a nested Ruby array by rows.
    def to_ary_cols
      ary = Array.new
      cola = Array.new
      coli = 0
      each_index_by_cols do |row, col|
        if coli != col
          coli = col
          ary << cola
          cola = Array.new
        end

        cola << self[row, col]
      end

      ary << cola
      ary
    end

    # Get the value at +row+,+col+
    def [] (row, col)
      _get(gsl, row, col)
    end

    # Set the value at +row+,+col+ to +val+.
    def []= (row, col, val)
      _set(gsl, row, col, val)
    end

    def set_all!(val)
      _set_all(gsl)
      self
    end

    def set_zero!
      _set_zero(gsl)
      self
    end

    def set_identity!
      _set_identity(gsl)
      self
    end

    # Compute the transpose of the matrix.  Note that the BLAS
    # multiplaction methods provide the opportunity to transpose
    # before a matrix multiplication which may be more efficient if
    # the transposed matrix is only needed once.
    def transpose
      result = self.class.new(cols, rows)
      _transpose_memcpy(result.gsl, self.gsl)
      result
    end

    # Transpose in place, modifying +self+.
    def transpose!
      _transpose(self.gsl)
      @size = [@gsl[:rows], @gsl[:cols]]
      self
    end

    class Double
      include Matrix
      define_foreign_methods :double
    end

    class Float
      include Matrix
      define_foreign_methods :float
    end

  end

end
