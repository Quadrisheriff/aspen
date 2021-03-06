module Aspen

  Edge = Struct.new(:word, :context) do
    def text
      word.match(Aspen::Statement::EDGE).captures.first
    end

    def reciprocal?
      context.reciprocal? text
    rescue Aspen::ConfigurationError
      false
    end

    def to_cypher
      str = "[:#{text.parameterize.underscore.upcase}]"
      if reciprocal?
        "-#{str}-"
      else
        "-#{str}->"
      end
    end
  end

end
