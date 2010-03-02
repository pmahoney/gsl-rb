require 'gsl/gsl'

module GSL

  class Continue < RuntimeError; end
  class Error < RuntimeError
    class Domain < Error; end
    class Range < Error; end
    class NoMem < Error; end
    class Invalid < Error; end
    class Failed < Error; end
    class Factor < Error; end
    class Sanity < Error; end
    class NoMem < Error; end
    class BadFunc < Error; end
    class Runaway < Error; end
    class MaxIter < Error; end
    class ZeroDiv < Error; end
    class BadTolerance < Error; end
    class Tolerance < Error; end
    class Underflow < Error; end
    class Overflow < Error; end
    class Loss < Error; end
    class Round < Error; end
    class BadLen < Error; end
    class NotSquare < Error; end
    class Singularity < Error; end
    class Divergent < Error; end
    class Unsupported < Error; end
    class Unimplemented < Error; end
    class Cache < Error; end
    class Table < Error; end
    class NoProgress < Error; end
    class NoProgressJacobian < Error; end
    class ToleranceF < Error; end
    class ToleranceX < Error; end
    class ToleranceG < Error; end
    class EOF < Error; end
  end

  def self.status_to_err_class(status)
    case GSL.enum_value(:status, status)
    when :success then nil
    when :failure then Error
    when :continue then Continue
    when :edom then Error::Domainn
    when :erange then Error::Range
    when :efault then Error::NoMem
    when :einval then Error::Invalid
    when :efailed then Error::Failed
    when :efactor then Error::Factor
    when :esanity then Error::Sanity
    when :enomem then Error::NoMem
    when :ebadfunc then Error::BadFunc
    when :erunaway then Error::Runaway
    when :emaxiter then Error::MaxIter
    when :ezerodiv then Error::ZeroDiv
    when :ebadtol then Error::BadTolerance
    when :etol then Error::Tolerance
    when :eunderflw then Error::Underflow
    when :eovrflw then Error::Overflow
    when :eloss then Error::Loss
    when :eround then Error::Round
    when :ebadlen then Error::BadLen
    when :enotsqr then Error::NotSquare
    when :esing then Error::Singularity
    when :ediverge then Error::Divergent
    when :eunsup then Error::Unsupported
    when :eunimpl then Error::Unimplemented
    when :ecache then Error::Cache
    when :etable then Error::Table
    when :enoprog then Error::NoProgress
    when :enoprogj then Error::NoProgressJacob
    when :etolf then Error::ToleranceF
    when :etolx then Error::ToleranceX
    when :etolg then Error::ToleranceG
    when :eof then Error::EOF
    else
      Error
    end
  end

  callback :gsl_error_handler_t, [:string, :string, :int, :int], :void
  attach_function(:gsl_set_error_handler,
                  [:gsl_error_handler_t], :pointer)

  ERROR_HANDLER = proc do |reason, file, line, errno|
    klass = GSL.status_to_err_class(errno) || Error
    raise klass.new("%s (%s:%d)" % [reason, file, line])
  end
  GSL.gsl_set_error_handler(ERROR_HANDLER)

  attach_function :gsl_strerror, [:int], :string

  def self.strerror(status)
    GSL.gsl_strerror(status)
  end

end
