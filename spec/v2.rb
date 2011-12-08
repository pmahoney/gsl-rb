require File.join(File.dirname(__FILE__), 'spec_helper')

10000.times do |i|
  describe 'GSL::Vector#to_ary' do
    it 'returns a Ruby array of the vector values' do
      a = [1,2,3,4,5,6,7,8,9]

      v = GSL::Vector.new(a)
      v.to_ary.should == a

      v = GSL::Vector.new(1000)
      v.set_all!(10)
      v[0].should == 10
      v[10].should == 10
      v[100].should == 10
      v = nil
    end
  end
end
