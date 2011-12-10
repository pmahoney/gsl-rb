require 'spec_helper'

# Note: test cases at this point all fit inside a uchar (0-127).
# TODO: paramaterize this better to more fully test doubles etc.

class MatrixSpec < MiniTest::Spec
  def klass
    GSL::Matrix
  end

  it 'allows instantiation' do
    v = klass.new(1, 1)
    v.must_be_instance_of(klass)
  end

  it 'gets and sets elements' do
    v = klass.new(10, 10)
    10.times do |i|
      10.times do |j|
        v.set!(i, j, i*j)
      end
    end

    10.times do |i|
      10.times do |j|
        v.get(i, j).must_equal(i*j)
      end
    end
  end

  it 'sets all elements' do
    size = 10
    v = klass.new(size, size)
    v.set_all!(10)
    size.times do |i|
      size.times do |j|
        v.get(i, j).must_equal(10)
      end
    end

    v.set_all!(111)
    size.times do |i|
      size.times do |j|
        v.get(i, j).must_equal(111)
      end
    end
  end

  it 'adds other matricies to it' do
    a = klass.new(10,10)
    b = klass.new(10,10)
    a.set_all!(43)
    b.set_all!(32)

    a.add!(b)

    10.times do |i|
      10.times do |j|
        a.get(i, j).must_equal(75)
      end
    end
  end

  it 'raises error on zero size' do
    # lambda {klass.new(0,1)}.must_raise(Exception)
    # lambda {klass.new(1,0)}.must_raise(Exception)
    # lambda {klass.new(0,0)}.must_raise(Exception)
  end
end

# Create test class for each matrix type.  Run those same tests.
[GSL::Matrix::Char,
 GSL::Matrix::Complex,
 GSL::Matrix::Complex::Float,
 #           GSL::Matrix::Complex::LongDouble,
 GSL::Matrix::Float,
 GSL::Matrix::Int,
 #           GSL::Matrix::LongDouble,
 GSL::Matrix::Long,
 GSL::Matrix::Short,
 GSL::Matrix::UChar,
 GSL::Matrix::UInt,
 GSL::Matrix::ULong,
 GSL::Matrix::UShort].each do |klass|
  elements = klass.to_s.split('::')
  elements.shift
  test_class_name = elements.join('') + 'Spec'
  eval %Q{
    class #{test_class_name} < MatrixSpec
      def klass
        #{klass}
      end
    end
  }
end
