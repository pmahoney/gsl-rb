require 'spec_helper'

module GSL

  # Note: test cases at this point all fit inside a uchar (0-127).
  # TODO: paramaterize this better to more fully test doubles etc.

  module Vector
    module Spec
      def klass
        raise 'subclass must define #klass'
      end

      def test_allows_instantiation
        v = klass.new(1)
        v.must_be_instance_of(klass)
      end

      def test_gets_and_sets_elements
        v = klass.new(10)
        10.times do |i|
          v.set!(i, i+2)
        end

        10.times do |i|
          v.get(i).must_equal(i+2)
        end
      end
    end

    # Create test class for each matrix type.  Run those same tests.
    [Char,
     Complex,
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
