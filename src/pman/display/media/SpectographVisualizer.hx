package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.graphics.Color;
import tannus.html.Win;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;

import pman.core.*;
import pman.media.*;
import pman.display.media.LocalMediaObjectRenderer in Lmor;

import electron.Tools.defer;
import Std.*;
import tannus.math.TMath.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class SpectographVisualizer extends AudioVisualizer {
    /* Constructor Function */
    public function new(r):Void {
        super( r );

        leftData = null;
        rightData = null;
        colors = null;
    }

/* === Instance Methods === */

    override function attached(done : Void->Void):Void {
        super.attached(function() {
            fftSize = 1024;
            smoothing = 0.60;
            done();
        });
    }

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        c.save();
        var r = player.view.rect;
        c.clearRect(r.x, r.y, r.w, r.h);

        /*
        if ((renderer is LocalAudioRenderer)) {
            var ar:LocalAudioRenderer = cast renderer;
            if (ar.albumArt != null) {
                var aa:Image = ar.albumArt;
                c.drawComponent(aa, 0, 0, aa.width, aa.height, r.x, r.y, r.w, r.h);
            }
        }
        */

        waveform(stage, c);
    }

    /**
      * draw the waveform
      */
    private function waveform(stage:Stage, c:Ctx):Void {
        var colors = getColors();

        pullData();

        if (leftData != null && rightData != null) {
            if ( doubleRender ) {

                // draw the left-channel data
                drawWaveformPath(c, 1, colors[3], leftData);

                // draw the right channel data
                drawWaveformPath(c, 1, colors[1], rightData, {
                    value: invert
                });

                // draw the left-channel data
                drawWaveformPath(c, 2, colors[0], leftData, {
                    value: diminish.bind(_, 0.22)
                });

                // draw the right channel data
                drawWaveformPath(c, 2, colors[2], rightData, {
                    value: diminishedInvert.bind(_, 0.22)
                });

                // draw the left channel, inverted and diminished
                drawWaveformPath(c, 1, colors[3], leftData, {
                    value:  diminishedInvert.bind(_, 0.44)
                });

                // draw the right channel, diminished
                drawWaveformPath(c, 1, colors[1], rightData, {
                    value: diminish.bind(_, 0.44)
                });
            }
            else {
                // draw the left-channel data
                drawWaveformPath(c, 3, colors[0], leftData);

                // draw the right channel data
                drawWaveformPath(c, 3, colors[2], rightData, {
                    value: invert
                });
            }
        }

            /*
            // draw the left and right channels, but diminished and inverted
            if ( doubleRender ) {
                // left
                c.beginPath();
                c.strokeStyle = colors[3];
                c.lineWidth = 1;
                drawAudioDataVertices(leftData, c, {
                    value: diminishedInvert.bind(_, 0.44)
                });
                c.stroke();

                // right
                c.beginPath();
                c.strokeStyle = colors[1];
                c.lineWidth = 1;
                drawAudioDataVertices(rightData, c, {
                    value: diminish.bind(_, 0.44)
                });
                c.stroke();
            }
            */
    }

    /**
      * divide the given AudioData into two AudioDatas
      */
    private function split(d : AudioData<Int>):Pair<AudioData<Int>, AudioData<Int>> {
        var mid:Int = floor(d.length / 2);
        return new Pair(d.slice(0, mid), d.slice(mid));
    }

    private function drawWaveformPath(c:Ctx, lineWidth:Float, strokeStyle:Dynamic, data:AudioData<Int>, ?mod:Mod):Void {
        c.beginPath();
        c.strokeStyle = strokeStyle;
        c.lineWidth = lineWidth;
        drawAudioDataVertices(data, c, mod);
        c.stroke();
    }

	/**
	  * draw the spectograph for the given AudioData, onto the given Ctx
	  */
	public function drawAudioDataVertices(data:AudioData<Int>, c:Ctx, ?mod:Mod):Void {
		//var rect:Array<Int> = [ceil(player.view.w), ceil(player.view.h)];
		var mid:Float = (ceil( player.view.h ) / 2);
		var sliceWidth:Float = (ceil( player.view.w ) * 1.0 / data.length);
		var offset:Float, value:Int, n:Float, x:Float=0, y:Float;
		for (i in 0...data.length) {
			offset = ((data.length / 2) - abs((data.length / 2) - i));
			offset = (offset / (data.length / 2));
			if (mod != null && mod.offset != null) {
				offset = mod.offset( offset );
			}

			value = data[i];
			if (mod != null && mod.value != null) {
				value = mod.value( value );
			}
			//n = (value / 128.0);
			y = (mid + (mid - ((value / 128.0) * mid)) * offset);
			(i == 0 ? c.moveTo : c.lineTo)(x, y);
			x += sliceWidth;
		}
	}

	/**
	  * invert data
	  */
	private function invert(i : Int):Int {
	    return (255 - i);
	}

    /**
      * invert and diminish data
      */
	private function diminishedInvert(i:Int, amount:Float):Int {
	    return invert(diminish(i, amount));
	}

    /**
      * pull data
      */
    private function pullData():Void {
        var shouldPull:Bool = (configChanged || player.getStatus().match(Playing));
        if ( shouldPull ) {
            leftData = leftAnalyser.getByteTimeDomainData();
            rightData = rightAnalyser.getByteTimeDomainData();
            configChanged = false;
        }
    }

    /**
	  * used to decrease the magnitude of the waveform by 1/3
	  */
	private function diminish(value:Int, amount:Float):Int {
		var diff:Int = (128 - value);
		diff = floor(diff - (amount * diff));
		return (diff + 128);
	}

	/**
	  * get the color scheme of the waveform
	  */
	private function getColors():Array<String> {
		if (colors == null) {
			var base:Color = player.theme.secondary;
			var accent:Color = base.invert();
			var base2:Color = base.darken( 30 );
			var accent2:Color = accent.darken( 30 );

			colors = [base, base2, accent, accent2].map.fn(_.toString());
			return colors;
		}
		else {
		    return colors;
		}
	}

	/**
	  * get the viewport as a Rect
	  */
	private inline function getViewport():Rect<Float> {
	    return new Rect(vr.x, vr.y, vr.w, vr.h);
	}

/* === Computed Instance Fields === */

    private var vr(get, never):tannus.geom.Rectangle;
    private inline function get_vr() return player.view.rect;

/* === Instance Fields === */

    private var leftData:Null<AudioData<Int>>;
    private var rightData:Null<AudioData<Int>>;
    private var colors:Null<Array<String>>;

    private var doubleRender:Bool = true;
    private var quadRender:Bool = true;
}

// modifier for audio data rendering
typedef Mod = {
	?value : Int -> Int,
	?offset : Float -> Float
};
