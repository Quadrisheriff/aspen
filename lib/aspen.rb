require 'aspen/version'

require 'aspen/configuration'
require 'aspen/node'
require 'aspen/edge'
require 'aspen/statement'

require 'aspen/contracts'
require 'aspen/nickname_registry'

module Aspen

  class ConfigurationError < StandardError ; end
  class Error < StandardError ; end

  def self.compile_text(text)

    config_text, *split_body = text.partition("\n(")
    body = split_body.join().strip()

    config = Configuration.new(config_text)

    # SMELL: We introduce and remove `nil`s here.
    statements = body.lines.map do |line|
      next if line.strip.empty?
      Statement.from_text(line, context: config)
    end.compact

    node_statements = statements.flat_map(&:nodes).map { |n| "MERGE #{n.to_cypher}" }.uniq.join("\n")
    edge_statements = statements.map { |s| "MERGE #{s.to_cypher}" }.join("\n")

    <<~CYPHER
      #{node_statements}

      #{edge_statements}
      ;
    CYPHER
  end

end
