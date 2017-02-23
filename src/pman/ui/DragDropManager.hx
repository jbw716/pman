package pman.ui;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;
import tannus.http.*;
import tannus.media.Duration;
import tannus.media.TimeRange;
import tannus.media.TimeRanges;
import tannus.math.Random;

import pman.core.*;
import pman.ui.*;
import pman.db.*;
import pman.events.*;
import pman.media.*;

import Std.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class DragDropManager {
	/* Constructor Function */
	public function new(main : BPlayerMain):Void {
		app = main;
	}

/* === Instance Methods === */

	/**
	  * initialize [this]
	  */
	public function init():Void {
		bind_events();
	}

	/**
	  * bind the event handlers
	  */
	private function bind_events():Void {
		// the list of drag events being bound
		var events:Array<String> = ['dragenter', 'dragleave', 'dragover', 'dragend', 'drop'];
		var target = app.body;
		target.forwardEvents(events, null, DragDropEvent.fromJqEvent);
		target.on('dragenter', onDragEnter);
		target.on('dragleave', onDragLeave);
		target.on('dragover', onDragOver);
		target.on('dragend', onDragEnd);
		target.on('drop', onDrop);
	}

	/**
	  * when [this] manager becomes the drop target of the dragged object
	  */
	private function onDragEnter(event : DragDropEvent):Void {

	}

	/**
	  * when the dragged object leaves [this] manager's area of influence
	  */
	private function onDragLeave(event : DragDropEvent):Void {

	}

	/**
	  * as the dragged object is being dragged within [this] manager's area of influence
	  */
	private function onDragOver(event : DragDropEvent):Void {
		event.preventDefault();
	}

	/**
	  * when the current drag operation is being ended
	  */
	private function onDragEnd(event : DragDropEvent):Void {
		null;
	}

	/**
	  * when an object has just been dropped onto [this]
	  */
	private function onDrop(event : DragDropEvent):Void {
		// cancel default behavior
		event.preventDefault();
		// create the Array of Tracks
		var tracks:Array<Track> = new Array();
		// shorthand reference to [event.dataTransfer]
		var dt = event.dataTransfer;
		// if the DataTransfer has the [items] field
		if (dt.items != null) {
			for (item in dt.items) {
				if (item.kind == DKFile) {
					var file:File = new File(item.getFile().path);
					tracks.push(Track.fromFile( file ));
				}
				else if (item.kind == DKString) {
					trace({
						data: item.getString(),
						type: item.type
					});
				}
				else {
					continue;
				}
			}
		}
		// if it has the [files] field
		else if (dt.files != null) {
			for (webFile in dt.files) {
				var file:File = new File( webFile.path );
				tracks.push(Track.fromFile( file ));
			}
		}

		// load the Tracks into the Playlist
		app.player.addItemList(tracks, function() {
			trace( tracks );
		});
	}

/* === Instance Fields === */

	public var app : BPlayerMain;
}
