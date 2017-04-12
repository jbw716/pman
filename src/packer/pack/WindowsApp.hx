package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.Tools.*;
import Packer.TaskOptions;
import pack.PackStandalone;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class WindowsApp extends PackStandalone {
    /* Constructor Function */
    public function new(arch:String, ?opts:Array<PackagerOptions>):Void {
        super('win32', arch, opts);
    }
}