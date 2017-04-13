package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.node.*;
import tannus.node.Process;

import pack.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Tools {
    /**
      *
      */
    public static inline function defer(action : Void->Void):Void {
        ((untyped __js__('process')).nextTick( action ));
    }

    /**
      * get the absolute Path to the pack script
      */
    public static function path(?s : String):Path {
        var result:Path = Path.fromString(untyped __js__('__dirname'));
        if (s != null) {
            result = result.plusString( s );
        }
        return result;
    }

    /**
      * perform a batch of Tasks
      */
    public static function batch<T:Task>(tasks:Array<T>, callback:?Dynamic->Void):Void {
        var stack = new AsyncStack();
        for (t in tasks) {
            stack.push(function(next) {
                t.run(function(?error : Dynamic) {
                    if (error != null) {
                        callback( error );
                    }
                    else {
                        next();
                    }
                });
            });
        }
        stack.run(function() {
            callback();
        });
    }
}
