require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'GSL::Vector.new' do
  it 'creates a new vector' do
    v = GSL::Vector.new(1)
    v.should be_an_instance_of(GSL::Vector::Double)
  end

  it 'raises error on zero size' do
    lambda {v = GSL::Vector.new(0)}.should raise_error(GSL::Error::Invalid)
  end

  it 'accepts a Ruby array initializer' do
    ary = [3,5,7,9]
    v = GSL::Vector.new(ary)
    ary.each_index do |i|
      v[i].should == ary[i]
    end
  end
end

describe 'GSL::Vector#size' do
  it 'returns the size' do
    100.times do |i|
      v = GSL::Vector.new(i+1)
      v.size.should == i+1
    end
  end
end

describe 'GSL::Vector#[]' do
  before :each do
    @v = GSL::Vector.new(10)
    10.times do |i|
      @v[i] = i
    end
  end

  it 'gets values at indicies' do
    10.times do |i|
      @v[i].should == i
    end
  end
end

describe 'GSL::Vector#[]=' do
  before :each do
    @v = GSL::Vector.new(10)
  end

  it 'sets values at indicies' do
    10.times do |i|
      @v[i] = i*10 + 1
    end

    10.times do |i|
      @v[i].should == i*10+1
    end
  end
end

describe 'GSL::Vector#to_ary' do
  it 'returns a Ruby array of the vector values' do
    a = [1,2,3]
    b = [4,5,6,7,8,9]

    v = GSL::Vector.new(a)
    v.to_ary.should == a
    v = GSL::Vector.new(b)
    v.to_ary.should == b
  end
end

describe 'GSL::Vector#dup' do
  it 'creates a shallow copy' do
    v = GSL::Vector.new(50)
    50.times do |i|
      v[i] = i+1
    end

    d = v.dup
    d.should_not == v

    50.times do |i|
      v[i].should == i+1
      d[i].should == v[i]
    end

    v.set_zero!
    50.times do |i|
      v[i].should == 0
      d[i].should_not == 0
    end
  end
end

describe 'GSL::Vector#set_all!' do
  before :each do
    @v = GSL::Vector.new(50)
    50.times do |i|
      @v[i] = i
    end
  end

  it 'sets all values to a constant' do
    50.times do |i|
      next if i == 0
      @v[i].should_not == @v[i-1]
    end

    @v.set_all!(7)

    50.times do |i|
      next if i == 0
      @v[i].should == 7
    end
  end
end

describe 'GSL::Vector#set_zero!' do
  before :each do
    @v = GSL::Vector.new(50)
    50.times do |i|
      @v[i] = i
    end
  end

  it 'sets all values to a zero' do
    @v.set_zero!()

    50.times do |i|
      @v[i].should == 0
    end
  end
end

describe 'GSL::Vector#add!' do
  before :each do
    @v1 = GSL::Vector.new(10)
    @v2 = GSL::Vector.new(10)
    @v1.set_all!(1)
    @v2.set_all!(2)
  end

  it 'raises exception with unequal vectors' do
    vodd = GSL::Vector.new(8)
    lambda {@v1.add!(vodd)}.should raise_error(GSL::Error::BadLen)
  end

  it 'adds two vectors elementwise' do
    @v1.add!(@v2)
    10.times do |i|
      @v1[i].should == 3
    end
  end
end

describe 'GSL::Vector#sub!' do
  before :each do
    @v1 = GSL::Vector.new(10)
    @v2 = GSL::Vector.new(10)
    @v1.set_all!(5)
    @v2.set_all!(7)
  end

  it 'raises exception with unequal vectors' do
    vodd = GSL::Vector.new(8)
    lambda {@v1.sub!(vodd)}.should raise_error(GSL::Error::BadLen)
  end

  it 'subtracts two vectors elementwise' do
    @v2.sub!(@v1)
    10.times do |i|
      @v2[i].should == 2
    end
  end
end

describe 'GSL::Vector#mul!' do
  before :each do
    @v = GSL::Vector.new(10)
    10.times {|i| @v[i] = i}
  end

  it 'raises exception with unequal vectors' do
    vodd = GSL::Vector.new(8)
    lambda {@v.mul!(vodd)}.should raise_error(GSL::Error::BadLen)
  end

  it 'multiplies two vectors elementwise' do
    @v.mul!(@v)
    10.times do |i|
      @v[i].should == i*i
    end
  end
end

describe 'GSL::Vector#div!' do
  before :each do
    @v1 = GSL::Vector.new(10)
    @v2 = GSL::Vector.new(10)
    @v1.set_all!(10)
    @v2.set_all!(2)
  end

  it 'raises exception with unequal vectors' do
    vodd = GSL::Vector.new(8)
    lambda {@v1.sub!(vodd)}.should raise_error(GSL::Error::BadLen)
  end

  it 'divides two vectors elementwise' do
    @v1.div!(@v2)
    10.times do |i|
      @v1[i].should == 5
    end
  end
end
