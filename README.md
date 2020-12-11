# Scripts
Short form poetry

Generally FreeBSD/NetBSD/Darwin/Linux tested


Usage: xmlparse [-b][-c][-d][-f][-h][-k][-m path][-n #][-q][-s suffix][-t][-?] [URL or File or use stdin if nothing]

        -b      Ignore blank lines toggle (default ON)
        -c      Increase rawness content fields (parsed as XML -> HTML -> raw)
        -d      Increase verbosity
        -f      Stop parsing after nth match (see -m) per stream. Can specify multiple for multiple matches.
        -h      Ignore search for ?xml tag to start (e.g. parse HTML)
        -k      Toggle flatten key tag into path - key/val couplets as path/key/name/type:value
        -m      Match - only output if /path matches given path (at head)
        -n      Next n fields after match included (-s applies)
        -q      Do not prefix each line with /path: - just value
        -s      Suffix match - match backside (e.g. .jpg)
        -t      Ignore content layout tags like tables, divs, spans

        or - cat file.xml | xmlparse ...

        Examples
        Version of kext: plutil -convert xml1 -o - AppleALC.kext/Contents/Info.plist | xmlparse -m /plist/%/CFBundleShortVersionString -q -f
        Reddit RSS images with URLs: xmlparse -n 1 -m '/entry/content/a.href' -s '.jpg' -q 'https://reddit.com/r/cityporn/rising/.rss'

        Version 0.06 from 201124
