# fsinv: file system inventory tool

[![Gem Version](https://badge.fury.io/rb/fsinv.svg)](http://badge.fury.io/rb/fsinv)

imagine a very detailed README message here (please?)

## Installation

Just run ```gem install fsinv```

### Troubles with ruby-filemagic

If often happens that during installation rubygems tells you there is a problem with `lmagic`. This is usually the case if you do not have the `libmagic` library installed.

**On OSX**:

	brew install libmagic

**On Ubuntu**:

	apt-get install libmagic-dev

## Usage of the executable

	Usage: fsinv [options] basepath [basepath [...]]

	fsinv is used to index file systems. By default for each file/directory the size
	in bytes as well as creation time (ctime) and modification time (mtime) are indexed.

	Files additionally have their mime type, magic file description (see 'man file'),
	OSX Finder tags (kMDItemUserTags) if run on osx, and a special 'fshugo' extended
	file attribute (used by https://github.com/mpgirro/fshugo) stored as well.

	Directories have also their xattr (osx, fshugo) stored, as well as a count of their
	direct children files (file_count), direct children directories (dir_count) and a
	general children item count (all dir/item count throughout their descendent hierarchie
	tree)

	Multiple file system hierarchie trees can be indexed simultaniously, by using more than
	one basepath (see the usage)

	Note that some files are ignored (like .AppleDouble, .DS_Store, Thumbs.db, etc.)
	Additionally, some directories will only have reduced indizes (e.g. only their byte size,
	yet no children file list), for their content is huge of files, yet they are of lesser
	interest (like .git, .wine, etc.)

	On OSX system, some items appear as files yet are in fact directories (.app, .bundle)
	They will be marked as directories, but will only have their sizes calculated. Their
	inner file hierarchie is also of lesser interrest.

	Specific options:

	-a, --all                    Save in all formats to the default destinations.
                                 Equal to -b -j -q -x -y. Use -n to change the
                                 file names of all inventorys at once.
	--binary [FILE]              Dump inventory data in binary format. Default is ~/inventory.bin
	--crc32                      Calculate CRC32 checksum for files
	--db [FILE]                  Save inventory as SQLite database. Default is ~/inventory.db
	-j, --json [FILE]            Save inventory in JSON file format. Default is ~/inventory.json
	--md5                        Calculate MD5 hash for files
	-n, --name NAME              Change outputfile name. Default is 'inventory'.
                                 Specific targets for file formats will overwrite this.
	-p, --print FORMAT           Print a format to stdout (json|yaml|xml)
	-s, --silent                 No output or non-critical error messages will be printed
	-v, --verbose                Output processed filenames and non-critical errors too
	--xml [FILE]                 Save inventory in XML file format. Default is ~/inventory.xml
	--yaml [FILE]                Save inventory in YAML file format. Default is ~/inventory.yaml
	--version                    Show version
	-h, --help                   Show this message

## Usage as a library

Note: You must set ```Fsinv.options``` before using any Methods/Classes.
