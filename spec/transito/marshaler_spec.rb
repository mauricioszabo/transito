module Transito
  describe Marshaler do
    it "caches non-verbose handlers" do
      io = StringIO.new
      first  = Transito::Marshaler::Json.new(io,{}).instance_variable_get("@handlers")
      second = Transito::Marshaler::Json.new(io,{}).instance_variable_get("@handlers")
      third  = Transito::Marshaler::MessagePack.new(io,{}).instance_variable_get("@handlers")
      assert { first }
      assert { first.equal?(second) }
      assert { second.equal?(third) }
    end

    it "caches verbose handlers" do
      io = StringIO.new
      first  = Transito::Marshaler::VerboseJson.new(io,{}).instance_variable_get("@handlers")
      second = Transito::Marshaler::VerboseJson.new(io,{}).instance_variable_get("@handlers")
      assert { first }
      assert { first.equal?(second) }
    end

    it "caches verbose and non-verbose handlers separately" do
      io = StringIO.new
      first  = Transito::Marshaler::Json.new(io,{}).instance_variable_get("@handlers")
      second = Transito::Marshaler::VerboseJson.new(io,{}).instance_variable_get("@handlers")
      assert { first }
      assert { second }
      assert { !first.equal?(second) }
    end
  end
end
