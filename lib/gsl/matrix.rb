require 'gsl/gsl'

module GSL

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

    METHOD_FREE ||= [:free, [:uintptr_t], :void]

    METHODS_STANDARD ||=
      [[:alloc, [:size_t, :size_t], :pointer],
       [:calloc, [:size_t, :size_t], :pointer],

       [:get, [:pointer, :size_t, :size_t], :type],
       [:set, [:pointer, :size_t, :size_t, :type], :void],
       [:ptr, [:pointer, :size_t, :size_t], :pointer],
       [:const_ptr, [:pointer, :size_t, :size_t], :pointer],

       [:set_all, [:pointer, :type], :void],
       [:set_zero, [:pointer], :void],
       [:set_identity, [:pointer], :void],

       # TODO?: read/write to files
       # [:fwrite, [:pointer, :pointer], :int],
       # [:fread, [:pointer, :pointer], :int],
       # [:fprintf, [:pointer, :pointer, :string], :int],
       # [:fscanf, [:pointer, :pointer]],

       # TODO: views

       # TODO: row and column views

       [:memcpy, [:pointer, :pointer], :int],
       [:swap, [:pointer, :pointer], :int],

       [:get_row, [:pointer, :pointer, :size_t], :int],
       [:get_col, [:pointer, :pointer, :size_t], :int],
       [:set_row, [:pointer, :size_t, :pointer], :int],
       [:set_col, [:pointer, :size_t, :pointer], :int],

       [:swap_rows, [:pointer, :size_t, :size_t], :int],
       [:swap_columns, [:pointer, :size_t, :size_t], :int],
       [:swap_rowcol, [:pointer, :size_t, :size_t], :int],
       [:transpose_memcpy, [:pointer, :pointer], :int],
       [:transpose, [:pointer], :int],

       [:add, [:pointer, :pointer], :int],
       [:sub, [:pointer, :pointer], :int],
       [:mul_elements, [:pointer, :pointer], :int],
       [:div_elements, [:pointer, :pointer], :int],
       [:scale, [:pointer, :pointer], :int],
       [:add_constant, [:pointer, :pointer], :int]]

    class << self
      # Convenience method that simply calls
      # GSL::Vector::Double.new().
      def new(*args)
        GSL::Matrix::Double.new(*args)
      end

      def included(mod)
        mod.extend(GSL::Obj::Support)
        mod.extend(GSL::Obj::TypedSupport)
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

      @gsl = MatrixStruct.new(alloc(rows, cols))

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

    # Create a copy of the matrix.
    def dup
      d = super()
      d.send(:initialize, rows, cols)
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

      gsl_methods(:matrix, :double) do
        GSL::Matrix::METHODS_STANDARD.each {|m| attach(*m)}
        attach_class(*GSL::Matrix::METHOD_FREE)
      end
    end

    class Float
      include Matrix

      gsl_methods(:matrix, :float) do
        GSL::Matrix::METHODS_STANDARD.each {|m| attach(*m)}
        attach_class(*GSL::Matrix::METHOD_FREE)
      end
    end

  end

end
