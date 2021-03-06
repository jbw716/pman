package pman.ui.pl;

import tannus.ds.*;
import tannus.io.*;
import tannus.geom.*;
import tannus.html.Element;
import tannus.events.*;
import tannus.events.Key;

import crayon.*;
import foundation.*;

import gryffin.core.*;
import gryffin.display.*;

import electron.ext.*;
import electron.ext.Dialog;

import pman.core.*;
import pman.media.*;
import pman.search.TrackSearchEngine;

import Slambda.fn;
import tannus.ds.SortingTools.*;
import electron.Tools.*;

using StringTools;
using Lambda;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using tannus.ds.AnonTools;
using Slambda;
using tannus.ds.SortingTools;

class SearchWidget extends Pane {
	/* Constructor Function */
	public function new(p:Player, l:PlaylistView):Void {
		super();

		player = p;
		playlistView = l;

		build();
	}

/* === Instance Methods === */

	/**
	  * build [this]
	  */
	override function populate():Void {
		/*
		inputRow = new FlexRow([10, 2]);
		append( inputRow );
		*/
		searchInput = new TextInput();
		//inputRow.pane( 0 ).append( searchInput );
		append( searchInput );
		/*
		submitButton = new Button( 'go' );
		submitButton.small( true );
		submitButton.expand( true );
		inputRow.pane( 1 ).append( submitButton );
		*/

		clear = pman.display.Icons.clearIcon(64, 64).toFoundationImage();
		clear.addClass('clear');
		append( clear );

		__events();

		css.write({
			'width': '98%',
			'margin-left': 'auto',
			'margin-right': 'auto'
		});

		update(); } 
	/**
	  * update [this]
	  */
	public function update():Void {
	    if (searchInput.getValue() != null && searchInput.getValue() != '') { 
	        clear.css.write({
	            'display': 'block'
	        });
	        /*
            var sr = searchInput.rect();
            var cr = clear.rect();
            cr.centerY = sr.centerY;
            clear.css.write({
                'top': '${cr.y}px'
            });
            */
        }
        else {
            clear.css.write({
                'display': 'none'
            });
        }
	}

	/**
	  * handle keyup events
	  */
	private function onkeyup(event : KeyboardEvent):Void {
		switch ( event.key ) {
			case Enter:
				submit();
				searchInput.iel.blur();

			case Esc:
			    searchInput.iel.blur();

			default:
				null;
		}
	}

	/**
	  * the search has been 'submit'ed
	  */
	private function submit():Void {
		var d:SearchData = getData();
		
		if (d.search != null) {
			var engine = new TrackSearchEngine();
			engine.setContext(player.session.playlist.toArray());
			engine.setSearch( d.search );
			var matches = engine.getMatches();
			// sort the matches by relevancy
			matches.sort(function(x, y) {
				return -Reflect.compare(x.score, y.score);
			});
			var resultList:Playlist = new Playlist(matches.map.fn( _.item ));
			resultList.parent = player.session.playlist;
			player.session.setPlaylist( resultList );
		}
		else {
		    var pl = player.session.playlist;
		    player.session.setPlaylist(pl.getRootPlaylist());
		}

		defer( update );
	}

	/**
	  * get the data from [this] widget
	  */
	private function getData():SearchData {
		// get the search text
		var inputText:Null<String> = searchInput.getValue();
		if (inputText != null) {
			inputText = inputText.trim();
			if (inputText.empty()) {
				inputText = null;
			}
		}

		return {
			search: inputText
		};
	}

	/**
	  * bind event handlers
	  */
	private function __events():Void {
		searchInput.on('keydown', function(event : KeyboardEvent) {
			event.stopPropogation();
		});
		searchInput.on('keyup', onkeyup);
		clear.el.on('click', function(e) {
		    clearSearch();
		});
		//submitButton.on('click', function(event : MouseEvent) {
			//submit();
		//});
	}

	public function clearSearch():Void {
	    searchInput.setValue( null );
	    submit();
	}

/* === Instance Fields === */

	public var player : Player;
	public var playlistView : PlaylistView;

	public var inputRow : FlexRow;
	public var searchInput : TextInput;
	public var clear : foundation.Image;
	//public var submitButton : Button;
}

/**
  * typedef for the object that holds the form data
  */
typedef SearchData = {
	?search : String
};
