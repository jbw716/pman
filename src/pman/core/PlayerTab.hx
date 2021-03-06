package pman.core;

import haxe.extern.EitherType;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;
import tannus.math.Random;

import gryffin.core.*;
import gryffin.display.*;

import electron.ext.FileFilter;

import pman.media.*;
import pman.display.*;
import pman.display.media.*;
import pman.core.history.PlayerHistoryItem;
import pman.core.history.PlayerHistoryItem as PHItem;
import pman.core.PlayerPlaybackProperties;
import pman.core.JsonData;

import foundation.Tools.*;
import electron.Tools.*;

import haxe.Serializer;
import haxe.Unserializer;

using Std;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using tannus.math.RandomTools;

class PlayerTab {
    /* Constructor Function */
    public function new(sess : PlayerSession):Void {
        session = sess;

        playlist = new Playlist();
        focusedTrack = null;
    }

/* === Instance Methods === */

	/**
	  * check whether there is any media attached to [this] Tab
	  */
	public inline function hasMedia():Bool {
	    return (focusedTrack != null);
	}

/* === Computed Instance Fields === */

    // the Player instance
    public var player(get, never):Player;
    private inline function get_player() return session.player;

    // [focusedTrack] as a Maybe instance
    private var mft(get, never):Maybe<Track>;
    private inline function get_mft():Maybe<Track> return focusedTrack;

/* === Instance Fields === */

    public var session : PlayerSession;
    public var playlist : Playlist;
    public var focusedTrack : Null<Track>;
}
