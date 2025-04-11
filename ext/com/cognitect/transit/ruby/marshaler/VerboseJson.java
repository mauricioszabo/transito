// Copyright 2014 Cognitect. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS-IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
// implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package com.cognitect.transito.ruby.marshaler;

import java.io.OutputStream;
import java.util.Map;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transito.TransitFactory;
import com.cognitect.transito.WriteHandler;

@JRubyClass(name="Transito::Marshaler::VerboseJson")
public class VerboseJson extends Base {
    private static final long serialVersionUID = 7872087524091784518L;

    public VerboseJson(final Ruby runtime, RubyClass rubyClass) {
        super(runtime, rubyClass);
    }

    /**
      args[0] - io   : any Ruby IO
      args[1] - opts : Ruby Hash
    **/
    @JRubyMethod(name="new", meta=true, required=1, rest=true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject klazz, IRubyObject[] args) {
        RubyClass rubyClass = (RubyClass)context.getRuntime().getClassFromPath("Transito::Marshaler::VerboseJson");
        VerboseJson verbosejson = (VerboseJson)rubyClass.allocate();
        verbosejson.callMethod(context, "initialize", args);
        verbosejson.init(context, args);
        return verbosejson;
    }

    private void init(ThreadContext context, IRubyObject[] args) {
        OutputStream output = convertRubyIOToOutputStream(context, args[0]);
        Map<Class, WriteHandler<?, ?>> handlers = convertRubyHandlersToJavaHandler(context, args[1]);
        writer = TransitFactory.writer(TransitFactory.Format.JSON_VERBOSE, output, handlers);
    }

    @JRubyMethod
    public IRubyObject write(ThreadContext context, IRubyObject arg) {
        return super.write(context, arg);
    }
}
