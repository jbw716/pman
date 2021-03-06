
## PMan 

---

PMan is a desktop media player, written in the [Haxe](http://haxe.org) language, running on [Electron](http://electron.atom.io).


PMan is just a prototype at this stage, and plays only those codecs which are supported by Electron. 

---

#### Features

- sleek user interface
- reasonable performance
- save your playlists, restorable from the window menu under "Playlists"
- open entire directory (always recursive, need to change that)
- drag 'n drop files **and/or** folders onto window to open them
- freely rearrange your playlist
- shuffle
- supports importing playlists in several popular formats (m3u, pls, and xspf)
- export playlists in M3U or XSPF formats
- audio visualizations when playing music files
- progress through media is saved, so that the user can resume to that position next time that media is opened
- create bookmarks attached to a Track, allowing for quick navigation to one or more specific time offsets in the media
- tracks can be favorited. Favorited tracks are highlighted in the playlist view
- stream local media to chromecast (still **very** buggy)

#### Planned Features

- tags
- multiple tabs
- multiple windows
- send online media to chromecast
- stream local media to chromecast

---

#### Possible(?) Features

These are some features I'd love to see PMan have eventually, but that I either don't currently
know how to implement, don't have time to implement, or am simply unconvinced are feasible.

- using WebGL for the display, instead of 2D Canvas
- polyfilling some of the missing codecs with pure-Haxe implementations
- stream media via AirPlay
- scriptability, or support for extensions

