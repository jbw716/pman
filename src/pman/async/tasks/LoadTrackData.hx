package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import electron.Shell;

import pman.core.*;
import pman.media.*;
import pman.db.*;
import pman.db.MediaStore;
import pman.async.*;
import pman.media.info.*;

import Std.*;
import tannus.math.TMath.*;
import electron.Tools.defer;
import Slambda.fn;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;

class LoadTrackData extends Task2<TrackData> {
    /* Constructor Function */
    public function new(track:Track, db:PManDatabase):Void {
        super();

        this.track = track;
        this.db = db;
        this.store = db.mediaStore;
        this.data  = new TrackData( track );
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(done : Cb<TrackData>):Void {
        [tryto_load, fill_missing_info].series(function(?error:Dynamic) {
            if (error != null) {
                done(error, null);
            }
            else {
                done(null, data);
            }
        });
    }

    /**
      * attempt to load the data from the database
      */
    private function tryto_load(done : VoidCb):Void {
        switch ( track.source ) {
            case MediaSource.MSLocalPath( path ):
                if (!FileSystem.exists( path )) {
                    done(LoadTrackDataError.EFileNonExistant( path ));
                }
                else {
                    attempt_load( done );
                }

            default:
                attempt_load( done );
        }
    }

    /**
      * attempt to load the data from the database
      */
    private function attempt_load(done : VoidCb):Void {
        var uri:String = track.uri;
        store.getMediaItemRowByUri_(uri, function(?error:Dynamic, ?row:MediaItemRow) {
            if (error != null) {
                return done( error );
            }
            else {
                if (row == null) {
                    return create_new( done );
                }
                else {
                    store.getMediaInfoRow_(row.id, function(?error:Dynamic, ?irow:MediaInfoRow) {
                        if (error != null) {
                            return done( error );
                        }
                        data = new TrackData( track );
                        data.pullRaw( irow );
                        load_fields(irow, done);
                    });
                }
            }
        });
    }

    /**
      * load the data for the 'tags' and 'actors' fields
      */
    private function load_fields(row:MediaInfoRow, done:VoidCb):Void {
        [load_tags].map.fn(_.bind(row, _)).series( done );
    }

    /**
      * load tags
      */
    private function load_tags(row:MediaInfoRow, done:VoidCb):Void {
        var steps:Array<Async<Tag>> = row.tags.map.fn(tagId => db.tagsStore.pullTag.bind(tagId, _));
        steps.series(function(?error, ?tags:Array<Tag>) {
            if (error != null) {
                done( error );
            }
            else {
                for (tag in tags) {
                    data.attachTag( tag );
                }
                done();
            }
        });
    }

    /**
      * create new TrackData
      */
    private function create_new(done : VoidCb):Void {
        data = new TrackData( track );
        store.newMediaItemRowFor_(track.uri, function(?error:Dynamic, ?row) {
            if (error != null) {
                return done( error );
            }
            else {
                data.media_id = row.id;
                loadMediaMetadata(function(?error:Dynamic, ?md) {
                    if (error != null) {
                        if (error.name == 'ConstraintError') {
                            tryto_load( done );
                        }
                        else {
                            done(error);
                        }
                    }
                    else {
                        data.meta = md;
                        return push_data_to_db( done );
                    }
                });
            }
        });
    }

    /**
      * push some data to the database
      */
    private function push_data_to_db(done : VoidCb):Void {
        var raw = data.toRaw();
        store.putMediaInfoRow_(raw, function(error : Null<Dynamic>) {
            if (error != null) {
                return done( error );
            }
            else {
                done();
            }
        });
    }

    /**
      * attempt to fill in missing info and stuff
      */
    private function fill_missing_info(done : VoidCb):Void {
        if (data.meta == null || data.meta.isIncomplete()) {
            loadMediaMetadata(function(?error:Dynamic, ?meta) {
                if (error != null) {
                    return done( error );
                }
                else {
                    data.meta = meta;
                    done();
                }
            });
        }
        else {
            done();
        }
    }

    /**
      * get the media metadata
      */
    private function loadMediaMetadata(done : Cb<MediaMetadata>):Void {
        track.source.getMediaMetadata().then(done.yield()).unless(done.raise());
    }

/* === Instance Fields === */

    public var track : Track;
    public var db : PManDatabase;
    public var store : MediaStore;
    public var data : Null<TrackData>;
}

enum LoadTrackDataError {
    EFileNonExistant(path : Path);
}
