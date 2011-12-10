module GSL
  module Helper
    def underscore(camel_case_word)
      camel_case_word.to_s.gsub(/::/, '_').
#        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

    def make_finalizer(addr)
      proc { free(FFI::Pointer.new(addr)) }
    end

    # When inside GSL::Matrix::Float, when name is 'alloc',
    # returns 'gsl_matrix_float_alloc'.
    def gsl_name(name)
      underscore(self.to_s + '_' + name)
    end

    # When inside GSL::Matrix::Float,returns `[:gsl_matrix_float, :float]`
    def gsl_types
      scalar_type = case t = underscore(self.to_s.split('::')[-1]).to_sym
                    when :char, :complex, :float, :int, :long_double,
                      :long, :short, :uchar, :uint, :ulong, :ushort
                      t
                    else
                      :double
                    end
      [underscore(self).to_sym, scalar_type]
    end

    # Invoke the block within an instance of AttachDsl which knows the
    # local function name and (glboal) GSL name.
    #
    # For example, when in the module GSL::Matrix::Int, a local name
    # of 'get' has a GSL name of 'gsl_matrix_int_get'.
    def each_local_name(*local_names, &block)
      local_names.each do |local_name|
        dsl = AttachDsl.new(self, local_name, gsl_name(local_name))
        dsl.instance_eval &block
      end
    end

    def argstring(args)
      args.map { |a| a.to_s }.join(', ')
    end

    # Create a string that defines a method named
    # `local_name` that simply calls GSL.`gsl_name`.
    #
    # @param [String|Symbol] local_name
    # @param [String|Symbol] gsl_name
    # @param [Array] non_self_args array of string arg names
    # @param [Hash] opts
    def upcall(local_name, gsl_name, non_self_args = [], opts = {})
      decl_args = argstring(non_self_args)
      body_args = unless opts[:no_self]
                    argstring(['self'] + non_self_args)
                  else
                    decl_args
                  end

      local_name2 = if opts[:destructive]
                      local_name + '!'
                    else
                      local_name
                    end

      %Q{
        def #{local_name2}(#{decl_args})
          GSL.#{gsl_name}(#{body_args})
        end
      }
    end

    # Define a method at the instance level of self (a class method)
    # that simply calls a GSL function.
    def define_instance_upcall(local_name, gsl_name, args = [])
      instance_eval upcall(local_name, gsl_name, args, :no_self => true)
    end

    # Define a method at the module level of self (would become an
    # instance method) that simply calls a GSL function.
    def define_module_upcall(local_name, gsl_name, args = [])
      module_eval upcall(local_name, gsl_name, args)
    end

    # Define a destructive method ('!' is appended to the local method
    # name) at the module level of self (would become an instance
    # method) that simply calls a GSL function.
    def define_module_upcall!(local_name, gsl_name, args = [])
      module_eval upcall(local_name, gsl_name, args, :destructive => true)
    end
  end
end
