package pman.ui;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.sys.Path;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.ui.Border;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.ctrl.*;

import tannus.math.TMath.*;
import gryffin.Tools.*;

import motion.Actuate;
import motion.easing.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class SnapshotView extends Ent {
    /* Constructor Function */
    public function new(player:Player, path:Path, duration:Float=1500):Void {
        super();

        this.player = player;
        this.path = path;
        image = Image.load('file://' + path);
        this.duration = duration;
    }

/* === Instance Methods === */

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        calculateGeometry( player.view.rect );

        if (lastTime == null) {
            lastTime = now;
        }
        else {
            if ((now - lastTime) >= duration) {
                delete();
            }
        }
    }

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        c.drawComponent(image, 0, 0, image.width, image.height, x, y, w, h);
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rectangle):Void {
        r = player.view.mediaRect;
        w = (r.w * 0.2);
        h = (r.h * 0.2);
        x = r.x;
        y = r.y;
    }

/* === Instance Fields === */

    public var player : Player;
    public var path : Path;
    public var duration : Float;

    public var image : Image;
    private var lastTime : Null<Float> = null;
}
