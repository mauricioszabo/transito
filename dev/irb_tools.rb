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

require 'stringio'

def time
  start = Time.now
  yield
  puts "Elapsed: #{Time.now - start}"
end

class Object
  def to_transito(format=:json)
    sio = StringIO.new
    Transito::Writer.new(format, sio).write(self)
    sio.string
  end
end

class String
  def from_transito(format=:json)
    sio = StringIO.new(self)
    Transito::Reader.new(format, sio).read
  end
end
