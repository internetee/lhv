module Lhv
  class Config
    attr_reader :data

    def initialize(filename:)
      @data = YAML.load_file(Lhv.root.join(filename))
      define_reader_methods(data.keys)
    end

    private

    def define_reader_methods(names)
      names.each do |name|
        define_singleton_method(name) do
          data[name]
        end
      end
    end
  end
end
