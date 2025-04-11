# -*- ruby -*-

jruby_version=File.read("build/jruby_version").chomp

# dependency to transito-java
# this setup uses maven central for the repository

jar "com.cognitect:transito-java:0.8.287"

group 'development' do
  jar "org.jruby:jruby-complete:#{jruby_version}"
end
