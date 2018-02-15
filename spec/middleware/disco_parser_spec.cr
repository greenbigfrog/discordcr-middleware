require "../spec_helper"

module DiscordMiddleware
  describe DiscoParser do
    describe DiscoParser::Argument do
      describe "#parse" do
        it "parses a required argument" do
          arg = DiscoParser::Argument.new(DiscoParser::PARTS_RE.match("<a:int>").not_nil!)
          arg.name.should eq "a"
          arg.required.should be_true
          arg.count.should eq 1
          arg.types.should eq ["int"]
        end

        it "parses an optional argument" do
          arg = DiscoParser::Argument.new(DiscoParser::PARTS_RE.match("[a:int]").not_nil!)
          arg.required.should be_false
        end

        it "parses a flag" do
          arg = DiscoParser::Argument.new(DiscoParser::PARTS_RE.match("{a}").not_nil!)
          arg.name.should eq "a"
          arg.@flag.should be_true
        end

        it "parses catch-all" do
          arg = DiscoParser::Argument.new(DiscoParser::PARTS_RE.match("<foo:str...>").not_nil!)
          arg.types.should eq ["str"]
          arg.catch_all.should be_true
        end
      end

      describe "#count" do
        it "returns 1 when internal count is 0" do
          arg = DiscoParser::Argument.new(DiscoParser::PARTS_RE.match("<foo:str...>").not_nil!)
          arg.count.should eq 1
        end
      end
    end

    describe DiscoParser::ArgumentSet do
    end
  end
end
