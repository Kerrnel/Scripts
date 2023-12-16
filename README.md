# Scripts
Short form poetry

Generally FreeBSD/NetBSD/Darwin/Linux tested


Usage: Aerialist [install][4k][hdr][online][movies path][sound vol]

	Aerialist 1.10

	A rewrite of the Aerial screensaver

	Linux video screensaver gone wild - featuring
		AppleTV online or cached
		YouTube via youtube-dl and Seasons
		Resume where the video was last interrupted
		intermittent title/time overlay
		Install / pre-download of videos
			Run this same script with 'install' as a parameter
		Crontab like selection of season
			See "STABLE" below
		(e.g. Fireplace at night in Winter, Places, Animals by weekday)

	Parameters that are "fun" are up front
		Customize by puting overrides into ~/.config/aerialist
		in shell format



Usage: xmlp [-a][-b][-C][-c][-d][-f][-h][-i][-k][-K c][-l][-m path][-n #][-Q c][-q][-s suffix][-t][-V][-x][-?] [URL or pathToFile, will use stdin if available]

        -a      Array item numbers blank (useful when searching for any array item)
        -b      Ignore blank lines toggle (default ON)
        -C      Output CSV format
        -c      Increase rawness content fields (parsed as XML -> HTML -> raw)
        -d      Increase verbosity
        -e      Expand full paths (vs compressed . for each matching component to parent
        -f      Stop parsing after nth match (see -m) per stream. Can specify multiple for multiple matches.
        -h      Ignore search for ?xml tag to start (e.g. parse HTML)
        -i      Disable auto indexer (array detector)
        -k      Toggle flatten key tag into path - key/val couplets as path/key/name/type:value
        -K      Set dict/key compression character (default %)
        -l      Line break conversion to ;; for values (happens for comments by default)
        -L      Change ;; to this for newline replacement
        -m pth  Match - only output if /path matches given path (at head)
        -n cnt  Next n fields after match included (-s applies)
        -q      Do not prefix each line with /path: - just value
        -Q c    Quote character before and after values
        -s sfx  Suffix match - match backside (e.g. .jpg)
        -t      Ignore content layout tags like tables, divs, spans
        -V      Outpot in bash executable KV format (a=b where a legal variable name and b quoted value)
        -x      Output XML ... work in progress

        or - cat file.xml | xmlp ...

        Examples
        Version of macOS thing: xmlp -m %CFBundleShortVersionString -q -f /System/Applications/Mail.app/Contents/Info.plist
        Reddit RSS images with URLs: xmlp -n 1 -m '/entry/content/a.href' -s '.jpg' -q 'https://reddit.com/r/cityporn/rising/.rss'
        Use StdIn: cat /path/to/xmlfile.xml | xmlp
        CVS Output: xmlp -C https://www.w3schools.com/xml/plant_catalog.xml

        Issues: Wider range of XML file testing, more intelligent choices

        Version 0.14 from 230311


Usage: base [options] [ OutFormat ] InNumber [ InFormat ]

        Smartly convert between bases. Default Out Format is all of them

        Options
                -b      byteswap (MSB -> LSB) - shown anyway if no output specified
                -d      Force decode (needed for multiline base64 string)
                -e      Force encode
                -l      Same as -w 32
                -n      Number only - only one output, no label
                -s      String operations, not numeric
                -v      Increase verbosity
                -w      Width in bits

        Examples
                base 16384
                base 16 16384
                base 4000 16
                base QAA 64
                base 0u0u100000000000000        # binary
                base 0v10000000                 # base4
                base 0w40000                    # octal
                base 0x4000                     # hex
                base 0yIAAA                     # base32
                base 0zQAA                      # base64
                base -n 16 16384
                base -s "The quick brown fox"
                base -s VGhlIHF1aWNrIGJyb3duIGZveA==
                cat fileOfNumbers | base 64

        Version 0.09 from 210413
