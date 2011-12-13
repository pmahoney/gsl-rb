module GSL
  class AttachDsl
    attr_reader :mod, :local_name, :gsl_name

    def initialize(mod, local_name, gsl_name)
      @mod = mod
      @local_name = local_name
      @gsl_name = gsl_name
    end

    def attach_gsl_function(*args)
      GSL.attach_function(gsl_name, *args)
    end

    def define_instance_upcall(*args)
      mod.define_instance_upcall(local_name, gsl_name, args)
    end

    def define_module_upcall(*args)
      mod.define_module_upcall(local_name, gsl_name, args)
    end

    def define_module_upcall!(*args)
      mod.define_module_upcall!(local_name, gsl_name, args)
    end
  end
end
