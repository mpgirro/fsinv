# fsinv: file system inventory tool

imagine a very detailed here (please?)

## Usage

	Usage: fsinv.rb basepath1 [basepath2 [basepath3 [...]]] [options]

	fsinv is used to index file systems. By default for each file/directory the size
	in bytes as well as creation time (ctime) and modification time (mtime) are indexed.

	Files additionally have their mime type, magic file description (see 'man file'),
	OSX Finder tags (kMDItemUserTags) if run on osx, and a special 'fshugo' extended
	file attribute (used by https://github.com/mpgirro/fshugo) stored as well.

	Directories have also their xattr (osx, fshugo) stored, as well as a count of their
	direct children files (file_count), direct children directories (dir_count) and a
	general children item count (all dir/item count throughout their descendent hierarchie
	tree)

	Note that some files are ignored (like .AppleDouble, .DS_Store, Thumbs.db, etc.)
	Additionally, some directories will only have reduced indizes, for their content
	is huge of files, yet they are of lesser interest (like .git, .wine, etc.)
	On OSX system, some items appear as files yet are in fact directories (.app, .bundle)
	They will be marked as directories, but will only have their size calculated. Their
	inner file hierarchie is also of lesser interrest.

	Specific options:

	    -a, --all                        Save in all formats to the default destinations.
	                                     Equal to -b -j -q -x -y. Use -n to change the
	                                     file names of all target at once

	    -b, --binary [FILE]              Dump iventory data stuctures in binary format.
	                                     Default destination is inventory.bin

	    -c, --crc32                      Calculate CRC32 checksum for each file

	    -d, --db [FILE]                  Save inventory as SQLite database.
	                                     Default destination is inventory.db

	    -j, --json [FILE]                Save inventory in JSON file format.
	                                     Default destination is inventory.json

	    -m, --md5                        Calculate MD5 hashes for each file

	    -n, --name NAME                  This will change the name of the output files.
	                                     Default is 'inventory'. Specific targets for
	                                     file formats will overwrite this.

	    -p, --print FORMAT               Print a format to stdout (json|yaml|xml)

	    -s, --silent                     Run in silent mode. No output or non-critical
	                                     error messages will be printed

	    -v, --verbose                    Run verbosely. This will output processed
	                                     filenames and error messages too

	    -x, --xml [FILE]                 Save inventory in XML file format.
	                                     Default destination is inventory.xml

	    -y, --yaml [FILE]                Save inventory in YAML file format.
	                                     Default destination is inventory.yaml

	    -h, --help                       Show this message
