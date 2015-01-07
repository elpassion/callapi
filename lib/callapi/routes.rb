require 'active_support/core_ext/string'

class Callapi::Routes
  class << self
    def draw(&block)
      build_http_method_namespaces

      instance_eval &block
    end

    def get(*args)
      call_name, options = args[0], args[1]
      class_name_with_namespaces = namespaces + [call_name.camelize]

      class_name_with_namespaces.inject(Callapi::Get) do |namespace, class_name|
        if namespace.constants.include?(class_name.to_sym)
          namespace.const_get(class_name)
        else
          namespace.const_set(class_name, Class.new(Callapi::Call::Base)).tap do |klass|
            set_call_class_options(options, klass) if options
          end
        end
      end
    end

    def namespace(*args)
      add_namespace(args.shift)
      yield
      remove_namespace
    end

    private

    def set_call_class_options(options, klass)
      klass.strategy = options[:strategy] if options[:strategy]
    end

    def namespaces
      @namespaces ||= []
    end

    def add_namespace(namespace)
      namespaces << namespace.to_s.camelize
    end

    def remove_namespace
      namespaces.pop
    end

    def build_http_method_namespaces
      @build_http_method_namespaces ||= http_methods.each do |http_method|
        Callapi.const_set(http_method.to_s.camelize, Module.new)
      end
    end

    def http_methods
      Callapi::Call::Request::Http::HTTP_METHOD_TO_REQUEST_CLASS.keys
    end
  end
end