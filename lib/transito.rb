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


# WriteHandlers convert instances of Ruby types to their corresponding Transito
# semantic types, and ReadHandlers read convert transito values back into instances
# of Ruby types. transito-ruby ships with default sets of WriteHandlers for each
# of the Ruby types that map naturally to transito types, and ReadHandlers for each
# transito type. For the common case, the
# built-in handlers will suffice, but you can add your own extension types and/or
# override the built-in handlers.
#
# For example, Ruby has Date, Time, and DateTime, each with their
# own semantics. Transito has an instance type, which does not
# differentiate between Date and Time, so transito-ruby writes Dates,
# Times, and DateTimes as transito instances, and reads transito
# instances as DateTimes. If your application cares that Dates are
# different from DateTimes, you could register custom write and read
# handlers, overriding the built-in DateHandler and adding a new DateReadHandler.
#
# ```ruby
# class DateWriteHandler
#   def tag(_) "D" end
#   def rep(o) o.to_s end
#   def string_rep(o) o.to_s end
# end
#
# class DateReadHandler
#   def from_rep(rep)
#     Date.parse(rep)
#   end
# end
#
# io = StringIO.new('','w+')
# writer = Transito::Writer.new(:json, io, :handlers => {Date => DateWriteHandler.new})
# writer.write(Date.new(2014,7,22))
# io.string
# # => "[\"~#'\",\"~D2014-07-22\"]\n"
#
# reader = Transito::Reader.new(:json, StringIO.new(io.string), :handlers => {"D" => DateReadHandler.new})
# reader.read
# # => #<Date: 2014-07-22 ((2456861j,0s,0n),+0s,2299161j)>
# ```
module Transito
  ESC = "~"
  SUB = "^"
  RES = "`"
  TAG = "~#"
  MAP_AS_ARRAY = "^ "
  TIME_FORMAT  = "%FT%H:%M:%S.%LZ"
  QUOTE = "'"

  MAX_INT = 2**63 - 1
  MIN_INT = -2**63

  JSON_MAX_INT = 2**53 - 1
  JSON_MIN_INT = -JSON_MAX_INT

  def jruby?
    defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
  end
  module_function :jruby?
end

require 'set'
require 'time'
require 'uri'
require 'base64'
require 'bigdecimal'
require 'securerandom'
require 'forwardable'
require 'addressable/uri'
require_relative 'transito/date_time_util'
require_relative 'transito/transit_types'
require_relative 'transito/rolling_cache'
require_relative 'transito/write_handlers'
require_relative 'transito/read_handlers'
require_relative 'transito/marshaler/base'
require_relative 'transito/writer'
require_relative 'transito/decoder'
require_relative 'transito/reader'

if Transito::jruby?
  require 'lock_jar'
  LockJar.lock(File.join(File.dirname(__FILE__), "..", "Jarfile"))
  LockJar.load
  require 'transito.jar'
  require 'jruby'
  com.cognitect.transito.ruby.TransitService.new.basicLoad(JRuby.runtime)
  require 'transito/marshaler/jruby/json'
  require 'transito/marshaler/jruby/messagepack'
else
  require_relative 'transito/marshaler/cruby/json'
  require_relative 'transito/marshaler/cruby/messagepack'
  require_relative 'transito/unmarshaler/cruby/json'
  require_relative 'transito/unmarshaler/cruby/messagepack'
end
