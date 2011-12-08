require 'minitest/spec'
require 'minitest/autorun'
require 'gsl'

# Spec::Matchers.define :be_close_ary do |expected, delta|
#   match do |actual|
#     actual.each_index do |i|
#       return false unless (actual[i] - expected[i]).abs < delta
#     end
#     true
#   end

#   failure_message_for_should do |actual|
#     "expected #{_expected_} +/- (< #{_delta_}), got #{actual}"
#   end

#   failure_message_for_should_not do |actual|
#     "expected #{_expected_} +/- (< #{_delta_}), got #{actual}"
#   end

#   description do
#     "be close to #{_expected_} (within +- #{_delta_})"
#   end
# end
