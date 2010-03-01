require File.join(File.dirname(__FILE__), 'spec_helper')

require 'gsl/linalg'

describe 'GSL::Matrix#LU_decomp!' do
  it 'adds LU methods to the object' do
    m = GSL::Matrix.new([[1,2,3],
                         [4,5,6],
                         [7,8,9]])

    m.should_not respond_to(:solve)
    m.should_not respond_to(:inv)

    m.LU_decomp!

    m.should respond_to(:solve)
    m.should respond_to(:inv)
  end
end

describe 'GSL::Matrix#solve' do
  it 'solves a matrix equation Ax = b' do
    # From GSL documentation examples
    m = GSL::Matrix.new([[0.18, 0.60, 0.57, 0.96],
                         [0.41, 0.24, 0.99, 0.58],
                         [0.14, 0.30, 0.97, 0.66],
                         [0.51, 0.13, 0.19, 0.85]])

    v = GSL::Vector.new([1,2,3,4])

    ex = [-4.052,
          -12.606,
          1.661,
          8.694]

    m.LU_decomp!
    ans = m.solve(v)
    ans.to_ary.should be_close_ary(ex, 0.01)
  end
end
