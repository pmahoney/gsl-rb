require 'gsl/gsl'

module GSL
  module Vector
    module Functions
      def self.included(mod)
        mod.module_eval do
          extend Helper

          layout(:size, :size_t,
                 :stride, :size_t,
                 :data, :pointer,
                 :block, :pointer,
                 :owner, :int)

          vector_type, scalar_type = gsl_types
          GSL.typedef :pointer, vector_type

          each_local_name('alloc', 'calloc') do
            attach_gsl_function([:size_t], vector_type)
            define_instance_upcall(:n)
          end

          each_local_name('free') do
            attach_gsl_function([vector_type], :void)
            define_instance_upcall(:ptr)
            define_module_upcall
          end
        end

        def initialize(n, opts={})
          if opts[:zero]
            super(self.class.calloc(n))
          else
            super(self.class.alloc(n))
          end

          fin = self.class.make_finalizer(to_ptr.address)
          ObjectSpace.define_finalizer(self, fin)
        end
      end
    end
  end
end
