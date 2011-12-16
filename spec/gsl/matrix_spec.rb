require 'spec_helper'

module GSL

  # Note: test cases at this point all fit inside a uchar (0-127).
  # TODO: paramaterize this better to more fully test doubles etc.

  module Matrix
    module Spec
      def klass
        raise 'subclass must define #klass'
      end

      def test_allows_instantiation
        v = klass.new(1, 1)
        v.must_be_instance_of(klass)
      end

      def test_gets_and_sets_elements
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

      def test_sets_all_elements
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

      def adds_other_matricies_to_it
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

      def raises_error_on_zero_size
        lambda {klass.new(0,1)}.must_raise(GSL::Error::Invalid)
        lambda {klass.new(1,0)}.must_raise(GSL::Error::Invalid)
        lambda {klass.new(0,0)}.must_raise(GSL::Error::Invalid)
      end
    end

    # Create test class for each matrix type.  Run those same tests.
    [Char,
     Complex,
     Float,
     #      Complex::LongDouble,
     Double,
     Float,
     Int,
     #      LongDouble,
     Long,
     Short,
     UChar,
     UInt,
     ULong,
     UShort].each do |klass|
      eval %Q{
        class #{klass.to_s + 'Spec'} < MiniTest::Spec
          include Spec

          def klass
            #{klass}
          end
        end
      }
    end
  end
end
