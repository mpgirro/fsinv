# fsinv: file system inventory tool

	Usage: fsinv.rb basepath1 [basepath2 [basepath3 [...]]] [options]

	Specific options:
	    -a, --all                        Save in all formats to the default destinations.
	                                     Equal to -b -j -q -x -y. Use -n to change the file names
	    -b, --binary [FILE]              Dump iventory data stuctures in binary format. Default destination is inventory.bin
	    -d, --db [FILE]                  Save inventory as SQLite database. Default destination is inventory.db
	    -j, --json [FILE]                Save inventory in JSON file format. Default destination is inventory.json
	    -n, --name INV_NAME              Name of the inventory. This will change the name of the output files.
	                                     Default is 'inventory'. Specific targets for file formats will overwrite this.
	    -p, --print FORMAT               Print a format to stdout (json|yaml|xml)
	    -s, --silent                     Run in silent mode. No output or non-critical error messages will be printed
	    -v, --verbose                    Run verbosely. This will output processed filenames and error messages too
	    -x, --xml [FILE]                 Save inventory in XML file format. Default destination is inventory.xml
	    -y, --yaml [FILE]                Save inventory in YAML file format. Default destination is inventory.yaml
	    -h, --help                       Show this message
