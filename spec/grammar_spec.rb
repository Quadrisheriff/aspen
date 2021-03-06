require 'aspen'

describe Aspen::Grammar do

  let(:context) { Aspen::Configuration.new("default Person, name") }

  let(:line) { "Matt gave Hélène $2,000." }

  # TODO: make sure it can add single or multiple matchers.

  context "with valid matchers" do
    let(:first_match_statement) { "(Person a) gave (Person b) $(numeric amt)." }
    let(:matchers) {
      [
        Aspen::Matcher.new(
          "(Person a) gave (Person b) $(numeric amt).",
          "{{{a}}}-[:GAVE_DONATION]->(:Donation { amount: {{amt}} })<-[:RECEIVED_DONATION]-{{{b}}}"
        ),
        Aspen::Matcher.new(
          "(Person a) donated $(numeric amt) to (Person b).",
          "{{{a}}}-[:GAVE_DONATION]->(:Donation { amount: {{amt}} })<-[:RECEIVED_DONATION]-{{{b}}}"
        )
      ]
    }

    let(:grammar) {
      grammar = Aspen::Grammar.new()
      grammar.add(matchers)
      grammar
    }

    it "returns the right matcher" do
      matcher = grammar.matcher_for(line).value!
      expect(matcher.statement).to eq(first_match_statement)
    end

    it "returns results" do
      expect(grammar.results_for(line).keys).to eq(["a", "b", "amt"])
    end
  end

end
