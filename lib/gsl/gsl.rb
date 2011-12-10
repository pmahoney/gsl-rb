module GSL
  extend FFI::Library

  ffi_lib 'm', 'gslcblas', 'gsl'

  class << self

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

  Status = enum(:success, 0,
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
                :eof)

  Order = enum(:row_major, 101,
               :col_major, 102)

  Transpose = enum(:no_trans, 111,
                   :trans, 112,
                   :conjtrans, 113)
  Uplo = enum(:upper, 121,
              :lower, 122)
  Diag = enum(:non_unit, 131,
              :unit, 132)
  Side = enum(:left, 141,
              :right, 142)

end


