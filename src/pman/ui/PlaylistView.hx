package pman.ui;

import tannus.ds.*;
import tannus.io.*;
import tannus.geom.*;
import tannus.html.Element;
import tannus.events.*;

import crayon.*;
import foundation.*;

import gryffin.core.*;
import gryffin.display.*;

import electron.ext.*;
import electron.ext.Dialog;

import electron.Tools.*;

import pman.core.*;
import pman.media.*;
import pman.media.PlaylistChange;
import pman.ui.pl.*;
import pman.search.Match as SearchMatch;

using StringTools;
using Lambda;
using Slambda;

class PlaylistView extends Pane {
	/* Constructor Function */
	public function new(p : Player):Void {
		super();

		addClasses(['right-panel', 'playlist']);

		player = p;
		tracks = new Array();
		_tc = new Map();

		build();
	}

/* === Instance Methods === */

	/**
	  * open [this] view
	  */
	public function open():Void {
		player.page.append( this );

		player.session.trackChanged.on( on_track_change );
		player.session.playlist.changeEvent.on( on_playlist_change );

		defer(function() {
            //searchWidget.searchInput.focus();
            scrollToActive();
            searchWidget.update();
		});
	}

	/**
	  * close [this] view
	  */
	public function close():Void {
		player.session.trackChanged.off( on_track_change );
		player.session.playlist.changeEvent.off( on_playlist_change );
		dispatch('close', null);
		detach();
	}

	/**
	  * build the contents of [this]
	  */
	override function populate():Void {
		buildRows();
		var hed = new Heading(4, 'Playlist');
		hed.css['color'] = 'white';
		if (player.session.name != null) {
		    hed.text = player.session.name;
		}
		hedRow.append( hed );
		buildSearchWidget();
		buildTrackList();

		forwardEvents(['click', 'mousedown', 'mouseup', 'mousemove', 'mouseleave'], null, MouseEvent.fromJqEvent);

        /*
        var resizeOptions = {
            handles: 'w'
        };
		el.plugin('resizable', [resizeOptions]);
		*/
	}

	/**
	  * refresh [this] view
	  */
	public function refresh():Void {
	    // save the current scroll pos
		//var scrollY:Float = el.scrollTop();
	    // rebuild track list
		rebuildTracks();
		// restore scroll pos
		//el.scrollTop( scrollY );
	}

	/**
	  * build out the rows
	  */
	private function buildRows():Void {
		hedRow = new Row();
		append( hedRow );
		searchRow = new Row();
		searchRow.addClass('search-box');
		append( searchRow );
		listRow = new Row();
		listRow.addClass('tracks');
		append( listRow );
	}

	/**
	  * build out the track list
	  */
	private function buildTrackList():Void {
		list = new List();
		listRow.append( list );
		list.el.plugin( 'disableSelection' );
		bindList();
		for (track in playlist) {
			var trackView:TrackView = tview( track ); 
			if (player.track == track) {
				trackView.focused( true );
			}
			if ( trackView.needsRebuild ) {
			    trackView.build();
			}
			addTrack( trackView );
		}
		defer(function() {
		    scrollToActive();
		});
	}

	/**
	  * tear down the track list
	  */
	private function undoTrackList():Void {
		for (track in tracks) {
			detachTrack( track );
		}
		tracks = new Array();
		if (list != null) {
			list.destroy();
        }
		list = null;
	}

	/**
	  * rebuild the TrackList
	  */
	public function rebuildTracks():Void {
		searchResultsMode = false;
		undoTrackList();
		buildTrackList();
	}

	/**
	  * rebuild the TrackList to show search results
	  */
	public function showSearchResults(matches : Array<SearchMatch<Track>>):Void {
		searchResultsMode = true;
		undoTrackList();
		buildMatchList( matches );
	}

	/**
	  * build the track list for the search-results view
	  */
	private function buildMatchList(matches : Array<SearchMatch<Track>>):Void {
		list = new List();
		listRow.append( list );
		list.el.plugin('disableSelection');
		bindList();
		for (match in matches) {
		    var view = tview( match.item );
			if (player.track == match.item) {
				view.focused( true );
			}
			addTrack( view );
		}
	}

	/**
	  * build out the search widget
	  */
	private function buildSearchWidget():Void {
		searchWidget = new SearchWidget(player, this);
		searchRow.append( searchWidget );
	}

	/**
	  * add a Track to [this]
	  */
	public inline function addTrack(tv : TrackView):Void {
		tracks.push( tv );
		list.addItem( tv );
	}

	/**
	  * detach a TrackView from [this]
	  */
	public inline function detachTrack(view : TrackView):Void {
	    tracks.remove( view );
	    list.removeItemFor( view );
	}

	/**
	  * scroll to the active track
	  */
	public function scrollToActive():Void {
	    if (player.track == null)
	        return ;
	    var active:Null<TrackView> = viewFor( player.track );
	    if (active == null)
	        return ;

	    var vr = rect();
	    vr.y += el.scrollTop();
	    var ar = active.rect();
	    var visible:Bool = active.el.plugin('isOnScreen');
	    if ( !visible ) {
	        // the center of the viewport
	        var y:Float = (ar.y - (vr.h / 3));
	        el.scrollTop( y );
	    }
	}

	/**
	  * create or get a TrackView for the given Track
	  */
	private function tview(t : Track):TrackView {
	    if (_tc.exists( t.uri )) {
	        return _tc[t.uri];
	    }
        else {
            var view = new TrackView(this, t);
            _tc[t.uri] = view;
            return view;
        }
	}

	/**
	  * react to 'track-change' events
	  */
	private function on_track_change(delta : Delta<Null<Track>>):Void {
		if (delta.previous != null) {
			var pv = viewFor( delta.previous );
			if (pv != null) {
				pv.focused( false );
			}
		}
		if (delta.current != null) {
			var cv = viewFor( delta.current );
			if (cv != null) {
				cv.focused( true );
			}
		}
		defer( scrollToActive );
	}

	/**
	  * react to playlist-changes
	  */
	private function on_playlist_change(change : PlaylistChange):Void {
        refresh();
	}

	

	/**
	  * delete [this]
	  */
	override function destroy():Void {
		super.destroy();
	}

	@:allow( pman.ui.pl.TrackView )
	private function findTrackViewByPoint(p : Point):Null<TrackView> {
		var lastPassed:Null<{t:TrackView, r:Rectangle}> = null;
		for (t in tracks) {
			var tr = t.rect();
			if (tr.containsPoint( p )) {
				return t;
			}
			else if (p.y > tr.y) {
				lastPassed = {t:t, r:tr};
			}
		}
		if (lastPassed != null) {
			return lastPassed.t;
		}
		else return null;
	}

    /**
      * bind events to the list
      */
	private function bindList():Void {
	    if (list != null) {
	        list.forwardEvents(['mousemove', 'mouseleave', 'mouseenter'], null, MouseEvent.fromJqEvent);
	    }

	    var sortOptions = {
            update: function(event, ui) {
                var item:Element = ui.item;
                var t:TrackView = item.children().data( 'view' );
                playlist.move(t.track, (function() return getIndexOf( t )));
            }
	    };
	    list.el.plugin('sortable', [sortOptions]);
	}

    /**
      * get the TrackView associated with the given Track
      */
    public inline function viewFor(track : Track):Null<TrackView> {
        return _tc[track.uri];
    }

    /**
      * get the index of the given TrackView
      */
	public function getIndexOf(t : TrackView):Int {
	    var lis:Element = new Element(list.el.children());
	    for (index in 0...lis.length) {
	        var li:Element = new Element(lis.at( index ));
	        var view:Null<TrackView> = li.children().data('view');
	        if (view != null && Std.is(view, TrackView) && view == t) {
	            return index;
	        } 
	    }
	    return -1;
	}

/* === Computed Instance Fields === */

	public var session(get, never):PlayerSession;
	private inline function get_session():PlayerSession return player.session;

	public var playlist(get, never):Playlist;
	private inline function get_playlist():Playlist return session.playlist;

	public var isOpen(get, never):Bool;
	private inline function get_isOpen():Bool {
	    return childOf( 'body' );
	}

/* === Instance Fields === */

	public var player : Player;
	public var tracks : Array<TrackView>;
	public var searchResultsMode : Bool = false;

	public var hedRow : Row;
	public var searchRow : Row;
	public var searchWidget : SearchWidget;
	public var listRow : Row;
	public var list : Null<List> = null;

	private var _tc : Map<String, TrackView>;
}
