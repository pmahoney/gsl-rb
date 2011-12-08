require 'ffi'

require 'gsl/gsl'
require 'gsl/matrix/char'
require 'gsl/matrix/complex'
require 'gsl/matrix/complex/float'
#require 'gsl/matrix/complex/long_double'
require 'gsl/matrix/float'
require 'gsl/matrix/int'
#require 'gsl/matrix/long_double'
require 'gsl/matrix/long'
require 'gsl/matrix/short'
require 'gsl/matrix/uchar'
require 'gsl/matrix/uint'
require 'gsl/matrix/ulong'
require 'gsl/matrix/uchar'
require 'gsl/matrix/ushort'

#require 'gsl/error'
#require 'gsl/vector'
#require 'gsl/matrix'

require 'gsl/symbols'

module GSL
  SYMBOLS.each do |sym|
    @routes.each do |rr|
      regex, receiver = rr
      if match = regex.match(sym)
        receiver.call(sym, match, self)
      end
    end if @routes
  end
end

3.times {
  GC.start

  [GSL::Matrix,
   GSL::Matrix::Char,
   GSL::Matrix::Complex,
   GSL::Matrix::Complex::Float,
#   GSL::Matrix::Complex::LongDouble,
   GSL::Matrix::Float,
   GSL::Matrix::Int,
#   GSL::Matrix::LongDouble,
   GSL::Matrix::Long,
   GSL::Matrix::Short,
   GSL::Matrix::UChar,
   GSL::Matrix::UInt,
   GSL::Matrix::ULong,
   GSL::Matrix::UShort].each do |klass|

    m1 = klass.new(10, 10)
    m2 = klass.new(10, 10)

    m1.add! m2
    
    puts m1
    m1 = nil
  end
}

abort 'goodbye'
  

