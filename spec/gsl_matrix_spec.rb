require 'spec_helper'

describe 'GSL::Matrix.new' do
  it 'creates a new matrix' do
    v = GSL::Matrix.new(1,1)
    v.must_be_instance_of(GSL::Matrix::Double)
  end

  it 'raises error on zero size' do
    lambda {GSL::Matrix.new(0,1)}.must_raise(GSL::Error::Invalid)
    lambda {GSL::Matrix.new(1,0)}.must_raise(GSL::Error::Invalid)
    lambda {GSL::Matrix.new(0,0)}.must_raise(GSL::Error::Invalid)
  end

  it 'accepts a flat Ruby array initializer' do
    ary = [1,2,3,
           4,5,6,
           7,8,9]
    m = GSL::Matrix.new(3, 3, ary)
    m.size.must_equal [3,3]
    m[0,0].must_equal 1
    m[0,2].must_equal 3
    m[1,1].must_equal 5
  end

  it 'accepts a nested Ruby array initializer' do
    ary = [[1,2,3],
           [4,5,6],
           [7,8,9]]
    m = GSL::Matrix.new(ary)
    m.size.must_equal [3,3]
    m[0,0].must_equal 1
    m[0,2].must_equal 3
    m[1,1].must_equal 5
  end
end

describe 'GSL::Matrix#size' do
  it 'returns an array of [rows,cols]' do
    m = GSL::Matrix.new(1,2)
    m.size.must_equal [1,2]
    m = GSL::Matrix.new(10,20)
    m.size.must_equal [10,20]
    m = GSL::Matrix.new(19,8)
    m.size.must_equal [19,8]
  end
end

describe 'GSL::Matrix#rows' do
  it 'returns the number of rows' do
    m = GSL::Matrix.new(1,2)
    m.rows.must_equal 1
    m = GSL::Matrix.new(10,20)
    m.rows.must_equal 10
    m = GSL::Matrix.new(19,8)
    m.rows.must_equal 19
  end
end

describe 'GSL::Matrix#cols' do
  it 'returns the number of columns' do
    m = GSL::Matrix.new(1,2)
    m.cols.must_equal 2
    m = GSL::Matrix.new(10,20)
    m.cols.must_equal 20
    m = GSL::Matrix.new(19,8)
    m.cols.must_equal 8
  end
end

describe 'GSL::Matrix#[]' do
  before :each do
    @m = GSL::Matrix.new(3,3)
    3.times do |row|
      3.times do |col|
        @m[row,col] = row*col
      end
    end
  end

  it 'gets values at indicies' do
    3.times do |row|
      3.times do |col|
        @m[row,col].must_equal row*col
      end
    end
  end
end

describe 'GSL::Matrix#[]=' do
  before :each do
    @m = GSL::Matrix.new(3,3)
  end

  it 'sets values at indicies' do
    3.times do |row|
      3.times do |col|
        @m[row,col] = row*col + 17
      end
    end

    3.times do |row|
      3.times do |col|
        @m[row,col].must_equal row*col + 17
      end
    end
  end
end

describe 'GSL::Matrix#to_ary' do
  it 'returns a flat Ruby array' do
    ary = [1,2,3,
           4,5,6,
           7,8,9]

    m = GSL::Matrix.new(3,3,ary)
    m.size.must_equal [3,3]
    m.to_ary.must_equal ary
  end
end

describe 'GSL::Matrix#to_ary_rows' do
  it 'returns a nested Ruby array by rows' do
    ary = [[1,2,3],
           [4,5,6],
           [7,8,9]]

    m = GSL::Matrix.new(ary)
    m.size.must_equal [3,3]
    m.to_ary_rows.must_equal ary
  end
end

describe 'GSL::Matrix#to_ary_cols' do
  it 'returns a nested Ruby array by cols' do
    ary = [[1,2,3],
           [4,5,6],
           [7,8,9]]

    m = GSL::Matrix.new(ary)
    m.size.must_equal [3,3]
    m.to_ary_cols.must_equal [[1,4,7], [2,5,8], [3,6,9]]
  end
end

describe 'GSL::Matrix#set_identity!' do
  it 'sets the matrix to the identity matrix' do
    GSL::Matrix.new(3,3).set_identity!.to_ary_rows.must_equal [[1,0,0],
                                                               [0,1,0],
                                                               [0,0,1]]
  end
end

describe 'GSL::Matrix#transpose' do
  it 'computes the transpose' do
    m =[[1,2,3], [4,6,5]]
    res = GSL::Matrix.new(m).transpose.to_ary_rows
    res.must_equal m.transpose
  end
end
