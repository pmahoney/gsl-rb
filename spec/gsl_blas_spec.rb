require 'spec_helper'
require 'gsl/blas'

def dot(a, b)
  prod = 0
  a.each_index do |i|
    prod += a[i]*b[i]
  end
  prod
end

describe 'GSL::Vector#dot' do
  it 'computes the dot product of two vectors' do
    a = [1,2,3]
    b = [4,5,6]
    v1 = GSL::Vector.new(a)
    v2 = GSL::Vector.new(b)
    v1.dot(v2).should == dot(a,b)
  end

  it 'raises error with unequal length vectors' do
    a = GSL::Vector.new([1,2])
    b = GSL::Vector.new([1,2,3])
    lambda { a.dot(b) }.should raise_error(GSL::Error::BadLen)
  end
end

describe 'GSL::Vector#magnitude' do
  it 'computes the magnitude of a vector' do
    GSL::Vector.new([1,0]).magnitude.should == 1
    GSL::Vector.new([0,1]).magnitude.should == 1
    GSL::Vector.new([1,1]).magnitude.should == Math.sqrt(2)
    GSL::Vector.new([3,4]).magnitude.should == 5
    GSL::Vector.new([-1,0]).magnitude.should == 1
    GSL::Vector.new([0,-1]).magnitude.should == 1
  end
end

describe 'GSL::Vector#asum' do
  it 'computes the sum of absolute values' do
    GSL::Vector.new([1,0]).asum.should == 1
    GSL::Vector.new([-1,0]).asum.should == 1
    GSL::Vector.new([1,2,3,4]).asum.should == 10
    GSL::Vector.new([1,-2,-3,4]).asum.should == 10
  end
end

describe 'GSL::Matrix#mul' do
  it 'computer the matrix product' do
    a = GSL::Matrix.new([[1,2,3],
                         [4,5,6],
                         [7,8,9],
                         [10,11,12]])
    b = GSL::Matrix.new([[-2],[1],[0]])

    a.mul(b).to_ary_rows.should == [[0],[-3],[-6],[-9]]
  end
end
