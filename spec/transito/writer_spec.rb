# Copyright 2014 Cognitect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'
require 'json'

module Transito
  describe Writer do
    let(:io) { StringIO.new('', 'w+') }
    let(:writer) { Writer.new(:json_verbose, io) }

    describe "marshaling transito types" do
      def self.bytes
        @bytes ||= SecureRandom.random_bytes
      end

      def self.marshals_scalar(label, value, rep, opts={})
        it "marshals #{label}", :focus => opts[:focus] do
          writer.write(value)
          assert { JSON.parse(io.string) == {"~#'" => rep} }
        end
      end

      def self.marshals_structure(label, value, rep, opts={})
        it "marshals #{label}", :focus => opts[:focus] do
          writer.write(value)
          assert { JSON.parse(io.string) == rep }
        end
      end

      marshals_scalar("a UUID",
                      UUID.new("dda5a83f-8f9d-4194-ae88-5745c8ca94a7"),
                      "~udda5a83f-8f9d-4194-ae88-5745c8ca94a7")
      marshals_scalar("a Transito::Symbol", Transito::Symbol.new("foo"), "~$foo" )
      marshals_scalar("a Fixnum", 9007199254740999, "~i9007199254740999")
      marshals_scalar("a Bignum", 9223372036854775806, "~i9223372036854775806")
      marshals_scalar("a Very Bignum", 4256768765123454321897654321234567, "~n4256768765123454321897654321234567")
      # Ruby's base64 encoding adds line feed in every 60 encoded
      # characters, while Java,
      # org.apache.commons.codec.binary.Base64, doesn't add any. Java
      # method has option to add line feed, but every 76 characters.
      # this divergence may be inevitable
      if Transito::jruby?
        marshals_scalar("a ByteArray", ByteArray.new(bytes), "~b#{ByteArray.new(bytes).to_base64}".gsub(/\n/, ""))
      else
        marshals_scalar("a ByteArray", ByteArray.new(bytes), "~b#{ByteArray.new(bytes).to_base64}")
      end
      marshals_scalar("an URI", Addressable::URI.parse("http://example.com/search"), "~rhttp://example.com/search")
      marshals_structure("a link",
                         Link.new(Addressable::URI.parse("http://example.com/search"), "search", nil, "link", nil),
                         {"~#link" =>
                           {"href" => "~rhttp://example.com/search",
                             "rel" => "search",
                             "name" => nil,
                             "render" => "link",
                             "prompt" => nil}})
      marshals_structure("a TaggedValue", TaggedValue.new("tag", "value"), {"~#tag" => "value"})
      marshals_structure("a ratio by Rational class", Rational(1, 3), {"~#ratio" => [1, 3]})
      marshals_structure("a Rational with big number", Rational(4953778853208128465, 636801457410081246), {"~#ratio" => ["~i4953778853208128465", "~i636801457410081246"]})
    end

    describe "custom handlers" do
      it "raises when a handler provides nil as a tag" do
        handler = Class.new do
          def tag(_) nil end
        end
        writer = Writer.new(:json_verbose, io, :handlers => {Date => handler.new})
        if Transito::jruby?
          assert { rescuing { writer.write(Date.today) }.message =~ /Not supported/ }
        else
          assert { rescuing { writer.write(Date.today) }.message =~ /must provide a non-nil tag/ }
        end
      end

      it "supports custom handlers for core types" do
        handler = Class.new do
          def tag(_) "s" end
          def rep(s) "MYSTRING: #{s}" end
          def string_rep(s) rep(s) end
        end
        writer = Writer.new(:json_verbose, io, :handlers => {String => handler.new})
        writer.write("this")
        assert { JSON.parse(io.string).values.first == "MYSTRING: this" }
      end

      it "supports custom handlers for custom types" do
        handler = Class.new do
          def tag(_) "person" end
          def rep(s) {:first_name => s.first_name} end
          def string_rep(s) s.first_name end
        end
        writer = Writer.new(:json_verbose, io, :handlers => {Person => handler.new})
        writer.write(Person.new("Russ"))
        assert { JSON.parse(io.string) == {"~#person" => { "~:first_name" => "Russ" } } }
      end

      it "supports verbose handlers" do
        phone_class = Class.new do
          attr_reader :p
          def initialize(p)
            @p = p
          end
        end
        handler = Class.new do
          def tag(_) "phone" end
          def rep(v) v.p end
          def string_rep(v) v.p.to_s end
          def verbose_handler
            Class.new do
              def tag(_) "phone" end
              def rep(v) "PHONE: #{v.p}" end
              def string_rep(v) rep(v) end
            end.new
          end
        end

        writer = Writer.new(:json, io, :handlers => {phone_class => handler.new})
        writer.write(phone_class.new(123456789))
        assert { JSON.parse(io.string) == ["~#phone", 123456789] }

        io.rewind

        writer = Writer.new(:json_verbose, io, :handlers => {phone_class => handler.new})
        writer.write(phone_class.new(123456789))
        assert { JSON.parse(io.string) == {"~#phone" => "PHONE: 123456789"} }
      end
    end

    describe "formats" do
      describe "JSON" do
        let(:writer) { Writer.new(:json, io) }

        it "translates some qualified keyword without needing to escape" do
          writer.write(:"hello__world")
          expect(JSON.parse(io.string)).to eql(["~#'", "~:hello/world"])
        end

        it "writes a map as an array prefixed with '^ '" do
          writer.write({:a => :b, 3 => 4})
          assert { JSON.parse(io.string) == ["^ ", "~:a", "~:b", "~i3", 4] }
        end

        it "writes a single-char tagged-value as a string" do
          writer.write([TaggedValue.new("a","bc")])
          assert { JSON.parse(io.string) == ["~abc"] }
        end

        it "writes a multi-char tagged-value as a 2-element array" do
          writer.write(TaggedValue.new("abc","def"))
          assert { JSON.parse(io.string) == ["~#abc", "def"] }
        end

        it "writes a Date as an encoded hash with ms" do
          writer.write([Date.new(2014,1,2)])
          assert { JSON.parse(io.string) == ["~m1388620800000"] }
        end

        it "writes a Time as an encoded hash with ms" do
          writer.write([(Time.at(1388631845) + 0.678)])
          assert { JSON.parse(io.string) == ["~m1388631845678"] }
        end

        it "writes a DateTime as an encoded hash with ms" do
          writer.write([(Time.at(1388631845) + 0.678).to_datetime])
          assert { JSON.parse(io.string) == ["~m1388631845678"] }
        end

        it "writes a quote as a tagged array" do
          writer.write("this")
          assert { JSON.parse(io.string) == ["~#'", "this"] }
        end

        it "writes an int map-key as an encoded string" do
          writer.write({1 => :one})
          assert { io.string =~ /~i1/ }
        end
      end

      describe "JSON_VERBOSE" do
        let(:writer) { Writer.new(:json_verbose, io) }

        it "does not use the cache" do
          writer.write([{"this" => "that"}, {"this" => "the other"}])
          assert { JSON.parse(io.string) == [{"this" => "that"}, {"this" => "the other"}] }
        end

        it "writes a single-char tagged-value as a string" do
          writer.write([TaggedValue.new("a","bc")])
          assert { JSON.parse(io.string) == ["~abc"] }
        end

        it "writes a multi-char tagged-value as a map" do
          writer.write(TaggedValue.new("abc","def"))
          assert { JSON.parse(io.string) == {"~#abc" => "def"} }
        end

        it "writes a Date as an encoded human-readable strings" do
          writer.write([Date.new(2014,1,2)])
          assert { JSON.parse(io.string) == ["~t2014-01-02T00:00:00.000Z"] }
        end

        it "writes a Time as an encoded human-readable strings" do
          writer.write([(Time.at(1388631845) + 0.678)])
          assert { JSON.parse(io.string) == ["~t2014-01-02T03:04:05.678Z"] }
        end

        it "writes a DateTime as an encoded human-readable strings" do
          writer.write([(Time.at(1388631845) + 0.678).to_datetime])
          assert { JSON.parse(io.string) == ["~t2014-01-02T03:04:05.678Z"] }
        end

        it "writes a quote as a tagged map" do
          writer.write("this")
          assert { JSON.parse(io.string) == {"~#'" => "this"} }
        end

        it "writes an int map-key as an encoded string" do
          writer.write({1 => :one})
          assert { io.string =~ /~i1/ }
        end
      end

      # JRuby skips these 3 examples since they use raw massage pack
      # api. Also, JRuby doesn't have good counterpart.
      describe "MESSAGE_PACK", :unless => Transito::jruby? do
        let(:writer) { Writer.new(:msgpack, io) }

        it "writes a single-char tagged-value as a 2-element array" do
          writer.write(TaggedValue.new("a","bc"))
          assert { MessagePack::Unpacker.new(StringIO.new(io.string)).read == ["~#'", "~abc"] }
        end

        it "writes a multi-char tagged-value as a 2-element array" do
          writer.write(TaggedValue.new("abc","def"))
          assert { MessagePack::Unpacker.new(StringIO.new(io.string)).read == ["~#abc", "def"] }
        end

        it "writes a top-level scalar as a quote-tagged value" do
          writer.write("this")
          assert { MessagePack::Unpacker.new(StringIO.new(io.string)).read == ["~#'", "this"] }
        end

        it "writes an int map-key as an int" do
          writer.write({1 => :one})
          assert { io.string.each_char.drop(1).first == "\u0001" }
        end
      end

      describe "ints" do
        it "encodes ints <= max signed 64 bit with 'i'" do
          1.upto(5).to_a.reverse.each do |n|
            io.rewind
            writer.write([(2**63) - n])
            assert { JSON.parse(io.string).first[1] == "i" }
          end
        end

        it "encodes ints > max signed 64 bit with 'n'" do
          0.upto(4).each do |n|
            io.rewind
            writer.write([(2**63) + n])
            assert { JSON.parse(io.string).first[1] == "n" }
          end
        end
      end

      describe "escaped strings" do
        [ESC, SUB, RES, "#{SUB} "].each do |c|
          it "escapes a String starting with #{c}" do
            writer.write("#{c}whatever")
            assert { JSON.parse(io.string) == {"#{TAG}#{QUOTE}" => "~#{c}whatever"}}
          end
        end
      end

      describe "edge cases" do
        it 'writes correct json for TaggedValues in a map-as-array (json)' do
          writer = Writer.new(:json, io)
          v = {7924023966712353515692932 => TaggedValue.new("ratio", [1, 3]),
               100 => TaggedValue.new("ratio", [1, 2])}
          writer.write(v)
          expected = ["^ ",
                      "~n7924023966712353515692932", ["~#ratio", [1,3]],
                      "~i100",["^1", [1,2]]]
          actual = io.string
          assert { JSON.parse(io.string) == expected }
        end

        it 'writes out strings starting with `' do
          v = "`~hello"
          writer.write([v])
          assert { JSON.parse(io.string).first == "~`~hello" }
        end

        it 'raises when there is no handler for the type at the top level' do
          if Transito::jruby?
            assert { rescuing { writer.write(Class.new.new) }.message =~ /Not supported/ }
          else
            assert { rescuing { writer.write(Class.new.new) }.message =~ /Can not find a Write Handler/ }
          end
        end

        it 'raises when there is no handler for the type' do
          if Transito::jruby?
            assert { rescuing { writer.write([Class.new.new]) }.message =~ /Not supported/ }
          else
            assert { rescuing { writer.write([Class.new.new]) }.message =~ /Can not find a Write Handler/ }
          end
        end
      end
    end
  end
end
