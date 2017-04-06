package ;

import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.Path;
import tannus.node.Fs as NodeFs;
import tannus.sys.FileSystem as Fs;

import electron.main.*;
import electron.main.Menu;
import electron.main.MenuItem;
import electron.ext.App;
import electron.Tools.defer;

import js.html.Window;

import tannus.TSys as Sys;

import pman.db.AppDir;
import pman.ipc.MainIpcCommands;
import pman.ww.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class Background {
	/* Constructor Function */
	public function new():Void {
		playerWindows = new Array();
		ipcCommands = new MainIpcCommands( this );
		ipcCommands.bind();
		appDir = new AppDir();
	}

/* === Instance Methods === */

	/**
	 * start [this] Background script
	 */
	public function start():Void {
		App.onReady( _ready );
		App.onAllClosed( _onAllClosed );

		_listen();
	}

    /**
      * stop the background script
      */
	public function close():Void {
	    App.quit();
	    /*
	    serverBoss.send('close', null);
	    serverBoss.kill();
	    */
	}

	/**
	  * open a new Player window
	  */
	public function openPlayerWindow(?cb : BrowserWindow -> Void):Void {
	    // create new hidden BrowserWindow
		var win:BrowserWindow = new BrowserWindow({
			show: false,
			icon: ap('assets/icon64.png').toString(),
			width: 640,
			height: 480
		});
		// load the html file onto that BrowserWindow
		var dir:Path = ap( 'pages/index.html' );
		win.loadURL( 'file://$dir' );
		// wait for the window to be ready
		win.once('ready-to-show', function() {
			win.show();
			win.maximize();
			win.focus();
			playerWindows.push( win );
			defer(function() {
                if (cb != null) {
                    cb( win );
                }
            });
		});
	}

	/**
	  * build the menu
	  */
	public function buildMenu():Menu {
	    var menu:Menu = new Menu();

	    var media = new MenuItem({
            label: 'Media',
            submenu: [
            {
                label: 'Open File(s)',
                accelerator: 'CommandOrControl+O',
                click: function(i:MenuItem, w:BrowserWindow) {
                    ic.send(w, 'OpenFile');
                }
            },
            {
                label: 'Open Directory',
                accelerator: 'CommandOrControl+F',
                click: function(i:MenuItem, w:BrowserWindow) {
                    ic.send(w, 'OpenDirectory');
                }
            },
            {type: 'separator'},
            {
                label: 'Save Playlist',
                click: function(i, w:BrowserWindow) {
                    ic.send(w, 'SavePlaylist');
                }
            }
            ]
	    });
	    menu.append( media );

	    var viewItem = new MenuItem({
            label: 'View',
            submenu: [
            {
                label: 'Playlist',
                accelerator: 'CommandOrControl+L',
                click: function(i, w:BrowserWindow) {
                    ic.send(w, 'TogglePlaylist');
                }
            },
            {
                label: 'Inspect Application',
                accelerator: 'CommandOrControl+Shift+J',
                click: function(i, w:BrowserWindow) {
                    w.webContents.toggleDevTools();
                }
            }
            ]
	    });
	    menu.append( viewItem );

	    var playlistOptions:Dynamic = {
            label: 'Playlist',
            submenu: untyped [
            {
                label: 'Clear',
                accelerator: 'CommandOrControl+W',
                click: function(i, w) ic.send(w, 'ClearPlaylist')
            },
            {
                label: 'Shuffle',
                click: function(i, w) ic.send(w, 'ShufflePlaylist')
            },
            {
                label: 'Save',
                accelerator: 'CommandOrControl+S',
                click: function(i, w) ic.send(w, 'SavePlaylist', [false])
            },
            {
                label: 'Save As',
                accelerator: 'CommandOrControl+Shift+S',
                click: function(i, w) ic.send(w, 'SavePlaylist', [true])
            },
            {
                label: 'Export',
                click: function(i, w) ic.send(w, 'ExportPlaylist')
            }
            ]
	    };
	    var openPlaylistOptions:Dynamic = {
            label: 'Load',
            submenu: []
	    };
	    playlistOptions.submenu.push( openPlaylistOptions );

	    var splNames = appDir.allSavedPlaylistNames();
	    for (name in splNames) {
	        openPlaylistOptions.submenu.push({
                label: name,
                click: function(i, w) {
                    ic.send(w, 'LoadPlaylist', [name]);
                }
	        });
	    }

	    var playlist = new MenuItem( playlistOptions );
	    menu.append( playlist );

	    var sessionOptions:Dynamic = {
            label: 'Session',
            submenu: [untyped
            {
                label: 'Save Current Session',
                click: function(i, w) ic.send(w, 'SaveSession')
            },
            {type: 'separator'}
            ]
	    };
	    var sessNames = appDir.allSavedSessionNames();
	    for (name in sessNames) {
	        sessionOptions.submenu.push({
                label: name,
                click: function(i, w) {
                    ic.send(w, 'LoadSession', [name]);
                }
	        });
	    }
	    var session = new MenuItem( sessionOptions );
	    menu.append( session );

	    return menu;
	}

	/**
	  * Update the application menu
	  */
	public inline function updateMenu():Void {
	    Menu.setApplicationMenu(buildMenu());
	}

	/**
	  * bind event handlers
	  */
	private function _listen():Void {
	    _watchFiles();
	}

	/**
	  * watch some files for stuff
	  */
	private function _watchFiles():Void {
	    var sessionsPath = appDir.sessionsPath();
	    if (!Fs.exists(sessionsPath.toString())) {
	        Fs.createDirectory(sessionsPath.toString());
	    }

	    var ssw = NodeFs.watch(sessionsPath.toString(), _sessionsFolderChanged);

	    var plPath = appDir.playlistsPath();
	    if (!Fs.exists(plPath.toString())) {
	        Fs.createDirectory(plPath.toString());
	    }

	    var plw = NodeFs.watch(plPath.toString(), _playlistFolderChanged);
	}

/* === Event Handlers === */

	/**
	 * when the Application is ready to start doing stuff
	 */
	private function _ready():Void {
	    #if release
	        null;
	    #else
            trace(' -- background process ready -- ');
        #end

		updateMenu();
		
		openPlayerWindow(function( bw ) {
			null;
		});

        /*
		serverBoss = Boss.hire_cp( 'server' );
		serverBoss.send('init', {
            appPath: App.getAppPath().toString()
		});
		*/
	}

	/**
	  * when a window closes
	  */
	private function _onAllClosed():Void {
	    close();
	}

	/**
	  * when the playlist folder changes
	  */
	private function _playlistFolderChanged(eventName:String, filename:String):Void {
	    updateMenu();
	}

	/**
	  * when the sessions folder changes
	  */
	private function _sessionsFolderChanged(eventName:String, filename:String):Void {
	    updateMenu();
	}

/* === Utility Methods === */

    /**
      * get paths descended from the application path
      */
	private function ap(?s : String):Path {
		var p:Path = (_p != null ? _p : (_p = App.getAppPath()));
		if (s != null)
			p = p.plusString( s );
		return p;
	}

    /**
      * get apps descended from the userdata path
      */
	private inline function uip(?s:String):Path {
	    return (s==null?App.getPath(UserData):App.getPath(UserData).plusString(s));
	}

/* === Computed Instance Fields === */

    public var ic(get, never):MainIpcCommands;
    private inline function get_ic() return ipcCommands;

/* === Instance Fields === */

	public var playerWindows : Array<BrowserWindow>;
	public var ipcCommands : MainIpcCommands;
	public var appDir : AppDir;
	//public var serverBoss : Boss;
	private var _p:Null<Path> = null;

	/* === Class Methods === */

	public static function main():Void {
		new Background().start();
	}
}
