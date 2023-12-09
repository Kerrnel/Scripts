#!/bin/sh
#############################################################################
gDate=231112
gVers=002
#############################################################################
#	A rewrite / rework of the ATV2 ATV4 Aerial screensaver script
#
#	(p) Public Domain, 2023 by (mostly)	Greg Kerr
#############################################################################
#
#	* Usage
#	
#	Call with 'install' (or look at 'install' below to see how) to install
#		into .xscreensaver file
#
#	Call with 'online' to support streaming (I may flip to ship)
#
#	* Notes
#	Video descriptions incomplete - could not find a table of them online
#		(See VideoDescription function below)
#
#	History
#	003	GLK	231113	Test/fix on NetBSD and 'install'
#	002	GLK	231112	Lock (workaround some leftovers detected), ONLINE option
#	001	GLK	231105	Partial rewrite
#
#	Changes to original (became almost a rewrite save for a few lines
#	If $MOVIES folder exists, find videos instead of predefined lists
#		(still used for streaming mode)
#	BSD (bourne/dash rewrite) compatible
#
#	Tested:		on Artix, Void, PopOS, FreeBSD
#	Requires:	mplayer, awk (install), sed, grep & freinds
#############################################################################
#					Parameters												#
# Options - override in ~/config/aerial with shell format
ONLINE=0			# Allow network video play
TEST=0				# Just show the video that would play
SUBTIME=2			# Description every this many minutes
MOVIES=/opt/ATV4	# path of MOVIES (required if ONLINE == 0)

# If ONLINE != 0 and if MOVIES is empty - get videos here
#	with static names in DayVdieos/NightVideos below
APPLEURL="https://sylvan.apple.com/Aerials/2x/Videos"		

# Terms that identify "night view" videos
NIGHTS='D011_C011 B005_C011 A009_C009 A011_C003 A015_C018 G004_C010
G010_C006 H012_C009 B005_C011 L004_C011 L012_c002 A006_C004
A009_C009 A011_C003 N008_C003 N013_C004 401C_1037'
############################################################################

# Global
MPID=0				# MPlayer pid
TESTME=''		# Fake a selection with test XYZ
OS_TYPE=$(uname -s)

# XDG
[ -z "$XDG_CONFIG_HOME" ] && XDG_CONFIG_HOME=~/'.config'
[ ! -d "$XDG_CONFIG_HOME" ] && mkdir -p "$XDG_CONFIG_HOME"
[ -z "$XDG_RUNTIME_DIR" ] && XDG_RUNTIME_DIR="/var/run/user/$(id -u)"
[ ! -d "$XDG_RUNTIME_DIR" ] && {
	mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null
	[ ! -d "$XDG_RUNTIME_DIR" ] && XDG_RUNTIME_DIR="/tmp/run-user-$(id -u)"
	mkdir -p "$XDG_RUNTIME_DIR"
 }
# database files to allow for no repeats when playing videos
# Subtitle to show occasional text
DAY_DB="$XDG_CONFIG_HOME/aerial-day"
NIGHT_DB="$XDG_CONFIG_HOME/aerial-night"
SUBTITLE="$XDG_CONFIG_HOME/aerial-now"

# Allow preferences override in .config/aerial
[ -e "$XDG_CONFIG_HOME/aerial" ] && . "$XDG_CONFIG_HOME/aerial"

Install()
 {
	local	o a c

	o=~/'.xscreensaver.pre-aerial'
	a=~/'.xscreensaver'

	if [ -s "$a" ]; then
		c="$0"
		[ "$c" != "${c#/}" ] || c="$(pwd)/$c"
		if grep -q "$c" "$a"; then
			echo "$c is already installed in $a"
		else
			echo "
------------------------------------------------------------------
INSTALL
	Original:	$o
	Aerial:		$a
	Command:	$c

Press return to install ${0##*/} into xscreensaver, Ctrl-C to quit

Type 'online' (no quotes) to install online stream support
------------------------------------------------------------------"
			read line
			cp -f "$a" "$o"
			echo "Installing [$c] as a screensaver..."
			if [ -s "$o" ]; then
				cat "$o" | awk -v "PRG=$c $line" '{ print $0;
					# Funky format of .xscreensaver prefs - why not redone in 6.0?!? ;)
					if ("programs:" == $1) print "\t\t\"Aerial\"\t" PRG "\t\t\t    \\n\\"
				 }' > "$a"
				echo 'Should be installed, here is the diff:
------'
				diff "$a" "$o"
			fi
		fi
	else
		echo 'Please launch xscreensaver-demo once to have a configuration file to install into.'
	fi
	exit 22
 }

# Install into xscreensaver and exit, test mode (just output what would happen)
while [ -n "$1" ]; do case "$1" in
  'install')	Install				;;
  'online')		ONLINE=1			;;
  'test')		TEST=1; TESTME="$2"	;;
esac; shift; done

# Lock for this display
lockf="$XDG_RUNTIME_DIR/.aerial.${DISPLAY#:}.lock"
if [ -e "$lockf" ]; then
	pid=$(head -n 1 "$lockf")
	case "$OS_TYPE" in
	  'Linux')	f='-h -q'	;;
	  *)		f='-p'		;;
	esac
	ps $f "$pid" && echo "Aerial locked by $pid in $lockf" && exit 33
fi
echo $$ > "$lockf"

# Show info in test mode
if [ $TEST -ne 0 ]; then
	echo "Aerial:	$gVers ($gDate)
XDG Conf:	$(ls -ld $XDG_CONFIG_HOME)
XDG Runt:	$(ls -ld $XDG_RUNTIME_DIR)
Mplayer:	$(which mplayer)
Process:	$$
Lockfile:	$lockf"
fi

# Plays the video - local and remote
command -v mplayer >/dev/null 2>&1 || {
  echo "${0##*/} requires mplayer but it's not installed. Aborting." >&2
  exit 11; }

Sources()
 {
# Future use
echo << 'EOSOURCES'
https://github.com/AerialScreensaver/AerialCommunity/raw/master/manifest.json
EOSOURCES
 }

Random()
 {
	# Return random 0 through $1-1
	local m="$(od -vAn -N4 -tu4 < /dev/urandom)"
	m=1$(date '+%S')"${m#*[0-9]}"
	[ $1 -eq 0 ] && OUT=0 || OUT=$(($m % $1))
	[ $TEST -ne 0 ] && echo "Random:		$OUT" >&2
 }

RandomLine()
 {
	local	pick
	Random $(cat "$1" | wc -l)
	pick=$((1 + $OUT))
	OUT=$(sed "${pick}q;d" "$1")	# Get the line
	case "$OS_TYPE" in
	  'FreeBSD')	sed -i '' "${pick}d" "$1"	;;
	  *)			sed -i "${pick}d" "$1"		;;	# Remove the line
	esac
 }

DayVideos()
 {
	local	i line
	Videos | while read line; do if [ -n "$line" ]; then
		for i in $NIGHTS; do if [ -n "$line" ]; then
			[ "$line" != "${line#*$i}" ] && line=''
		fi; done
		[ -n "$line" ] && echo "$line"
	fi; done
 }

NightVideos()
 {
	local	i line night
	Videos | while read line; do if [ -n "$line" ]; then
		night=''
		for i in $NIGHTS; do if [ -z "$night" ]; then
			[ "$line" != "${line#*$i}" ] && night="$line"
		fi; done
		[ -n "$night" ] && echo "$night"
	fi; done
 }

Videos()
 {
cat << 'EOLIST'
AK_A004_C012_SDR_20191217_SDR_2K_HEVC.mov
BO_A012_C031_SDR_20190726_SDR_2K_HEVC.mov
BO_A014_C008_SDR_20190719_SDR_2K_HEVC.mov
BO_A014_C023_SDR_20190717_F240F3709_SDR_2K_HEVC.mov
BO_A018_C029_SDR_20190812_SDR_2K_HEVC.mov
comp_1223LV_FLARE_v21_SDR_PS_FINAL_20180709_F0F5700_SDR_2K_HEVC.mov
comp_A001_C004_1207W5_v23_SDR_FINAL_20180706_SDR_2K_HEVC.mov
comp_A006_C003_1219EE_CC_v01_SDR_PS_FINAL_20180709_SDR_2K_HEVC.mov
comp_A007_C017_01156B_v02_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_A008_C007_011550_CC_v01_SDR_PS_FINAL_20180709_SDR_2K_HEVC.mov
comp_A009_C001_010181A_v09_SDR_PS_FINAL_20180725_SDR_2K_HEVC.mov
comp_A012_C014_1223PT_v53_SDR_PS_FINAL_20180709_F0F8700_SDR_2K_HEVC.mov
comp_A013_C012_0122D6_CC_v01_SDR_PS_FINAL_20180709_SDR_2K_HEVC.mov
comp_A083_C002_1130KZ_v04_SDR_PS_FINAL_20180725_SDR_2K_HEVC.mov
comp_A103_C002_0205DG_v12_SDR_FINAL_20180706_SDR_2K_HEVC.mov
comp_A105_C003_0212CT_FLARE_v10_SDR_PS_FINAL_20180711_SDR_2K_HEVC.mov
comp_A108_C001_v09_SDR_FINAL_22062018_SDR_2K_HEVC.mov
comp_A114_C001_0305OT_v10_SDR_FINAL_22062018_SDR_2K_HEVC.mov
comp_C001_C005_PS_v01_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_C003_C003_PS_v01_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_C004_C003_PS_v01_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_CH_C002_C005_PSNK_v05_SDR_PS_FINAL_20180709_SDR_2K_HEVC.mov
comp_CH_C007_C004_PSNK_v02_SDR_PS_FINAL_20180709_SDR_2K_HEVC.mov
comp_CH_C007_C011_PSNK_v02_SDR_PS_FINAL_20180709_SDR_2K_HEVC.mov
comp_DB_D008_C010_PSNK_v21_SDR_PS_20180914_F0F16157_SDR_2K_HEVC.mov
comp_GL_G002_C002_PSNK_v03_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_GMT026_363A_103NC_E1027_KOREA_JAPAN_NIGHT_v17_SDR_FINAL_25062018_SDR_2K_HEVC.mov
comp_GMT110_112NC_364D_1054_AURORA_ANTARTICA__COMP_FINAL_v34_PS_SDR_20181107_SDR_2K_HEVC.mov
comp_GMT306_139NC_139J_3066_CALI_TO_VEGAS_v07_SDR_FINAL_22062018_SDR_2K_HEVC.mov
comp_GMT307_136NC_134K_8277_NY_NIGHT_01_v25_SDR_PS_20180907_SDR_2K_AVC.mov
comp_GMT308_139K_142NC_CARIBBEAN_DAY_v09_SDR_FINAL_22062018_SDR_2K_HEVC.mov
comp_GMT312_162NC_139M_1041_AFRICA_NIGHT_v14_SDR_FINAL_20180706_SDR_2K_HEVC.mov
comp_GMT314_139M_170NC_NORTH_AMERICA_AURORA__COMP_v22_SDR_20181206_v12CC_SDR_2K_HEVC.mov
comp_GMT329_113NC_396B_1105_CHINA_v04_SDR_FINAL_20180706_F900F2700_SDR_2K_HEVC.mov
comp_GMT329_113NC_396B_1105_ITALY_v03_SDR_FINAL_20180706_SDR_2K_HEVC.mov
comp_GMT329_117NC_401C_1037_IRELAND_TO_ASIA_v48_SDR_PS_FINAL_20180725_F0F6300_SDR_2K_HEVC.mov
comp_H004_C007_PS_v02_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_H004_C009_PS_v01_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_H005_C012_PS_v01_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_H007_C003_PS_v01_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_HK_H004_C001_PSNK_DENOISE_v14_SDR_PS_FINAL_20180731_SDR_2K_HEVC.mov
comp_HK_H004_C008_PSNK_v19_SDR_PS_20180914_SDR_2K_HEVC.mov
comp_HK_H004_C010_PSNK_v08_SDR_PS_20181009_SDR_2K_HEVC.mov
comp_L007_C007_PS_v01_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_L010_C006_PS_v01_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_LA_A005_C009_PSNK_ALT_v09_SDR_PS_201809134_SDR_2K_HEVC.mov
comp_LA_A006_C008_PSNK_ALL_LOGOS_v10_SDR_PS_FINAL_20180801_SDR_2K_HEVC.mov
comp_LA_A008_C004_ALTB_ED_FROM_FLAME_RETIME_v46_SDR_PS_20180917_SDR_2K_HEVC.mov
comp_LW_L001_C003__PSNK_DENOISE_v04_SDR_PS_FINAL_20180803_SDR_2K_HEVC.mov
comp_LW_L001_C006_PSNK_DENOISE_v02_SDR_PS_FINAL_20180709_SDR_2K_HEVC.mov
comp_N003_C006_PS_v01_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_N008_C009_PS_v01_SDR_PS_20180925_SDR_2K_HEVC.mov
CR_A009_C007_SDR_20191113_SDR_2K_HEVC.mov
DB_D001_C001_2K_SDR_HEVC.mov
DB_D001_C005_2K_SDR_HEVC.mov
DB_D002_C003_2K_SDR_HEVC.mov
DB_D011_C009_2K_SDR_HEVC.mov
DL_B002_C011_SDR_20191122_SDR_2K_HEVC.mov
FK_U009_C004_SDR_20191220_SDR_2K_HEVC.mov
g201_AK_A003_C014_SDR_20191113_SDR_2K_HEVC.mov
g201_CA_A016_C002_SDR_20191114_SDR_2K_HEVC.mov
g201_TH_803_A001_8_SDR_20191031_SDR_2K_HEVC.mov
g201_TH_804_A001_8_SDR_20191031_SDR_2K_HEVC.mov
g201_WH_D004_L014_SDR_20191031_SDR_2K_HEVC.mov
GL_G002_C002_2K_SDR_HEVC.mov
GL_G004_C010_2K_SDR_HEVC.mov
HK_H004_C001_2K_SDR_HEVC.mov
HK_H004_C008_2K_SDR_HEVC.mov
HK_H004_C010_2K_SDR_HEVC.mov
HK_H004_C013_2K_SDR_HEVC.mov
KP_A010_C002_SDR_20190717_SDR_2K_HEVC.mov
LA_A005_C009_2K_SDR_HEVC.mov
LA_A006_C008_2K_SDR_HEVC.mov
LW_L001_C006_2K_SDR_HEVC.mov
MEX_A006_C008_SDR_20190923_SDR_2K_HEVC.mov
PA_A001_C007_SDR_20190717_SDR_2K_HEVC.mov
PA_A002_C009_SDR_20190730_ALT01_SDR_2K_HEVC.mov
PA_A004_C003_SDR_20190719_SDR_2K_HEVC.mov
PA_A010_C007_SDR_20190717_SDR_2K_HEVC.mov
RS_A008_C010_SDR_20191218_SDR_2K_HEVC.mov
SE_A016_C009_SDR_20190717_SDR_2K_HEVC.mov
DB_D011_C010_2K_SDR_HEVC.mov
HK_B005_C011_2K_SDR_HEVC.mov
LA_A009_C009_2K_SDR_HEVC.mov
LA_A011_C003_2K_SDR_HEVC.mov
comp_A015_C018_0128ZS_v03_SDR_PS_FINAL_20180709__SDR_2K_HEVC.mov
comp_GL_G004_C010_PSNK_v04_SDR_PS_FINAL_20180709_SDR_2K_HEVC.mov
comp_GL_G010_C006_PSNK_NOSUN_v12_SDR_PS_FINAL_20180709_SDR_2K_HEVC.mov
comp_H012_C009_PS_v01_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_HK_B005_C011_PSNK_v16_SDR_PS_20180914_SDR_2K_HEVC.mov
comp_L004_C011_PS_v01_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_L012_c002_PS_v01_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_LA_A006_C004_v01_SDR_FINAL_PS_20180730_SDR_2K_HEVC.mov
comp_LA_A009_C009_PSNK_v02_SDR_PS_FINAL_20180709_SDR_2K_HEVC.mov
comp_LA_A011_C003_DGRN_LNFIX_STAB_v57_SDR_PS_20181002_SDR_2K_HEVC.mov
comp_N008_C003_PS_v01_SDR_PS_20180925_SDR_2K_HEVC.mov
comp_N013_C004_PS_v01_SDR_PS_20180925_F1970F7193_SDR_2K_HEVC.mov
EOLIST
 }

Choose()
 {
	local	nightf i

	[ "$MOVIES" = "${MOVIES%/}" ] && MOVIES="${MOVIES}/"

	if [ "$TEST" -ne 0 ]; then
		echo "Day DB:		$DAY_DB
Night DB:	$NIGHT_DB" >&2
		rm -f "$DAY_DB" "$NIGHT_DB"
	fi

	# If db is empty, find all the '*.mov' videos in $MOVIES for night or day and stash in DAY_DB or NIGHT_DB
	# Select and delete one line from DAY_DB or NIGHT_DB, store in $CHOICE
	if [ ! -s "$DAY_DB" -o ! -s "$NIGHT_DB" ]; then
		# Night video identifiers
		nightf="-iname '*night*.mov'"
		for i in $NIGHTS; do
			nightf="$nightf -o -iname '*${i}*.mov'"
		done
		nightf="\( $nightf \)"
		[ $TEST -ne 0 ] && echo "
Find Day:	find \"$MOVIES\" -type f -iname '*.mov' '!' $nightf

Find Night:	find \"$MOVIES\" -type f $nightf
"
	fi
	[ -s "$DAY_DB" ] || eval find \"$MOVIES\" -type f -iname \'*.mov\' \'\!\' $nightf > "$DAY_DB"
	[ -s "$NIGHT_DB" ] || eval find \"$MOVIES\" -type f $nightf > "$NIGHT_DB"

	# Fall back to online videos if none were found in $MOVIES
	[ -s "$DAY_DB" ] || DayVideos > "$DAY_DB"
	[ -s "$NIGHT_DB" ] || NightVideos > "$NIGHT_DB"

	# set the time of day based on the local clock
	# where day is after 7AM and before 6PM
	hour=$(date +%H)
	[ "$hour" -gt 19 -o "$hour" -lt 7 ] && use_db="$NIGHT_DB" || use_db="$DAY_DB"

	# select at random a video to play from the day or night pools
	RandomLine "$use_db"
	[ -n "$TESTME" ] && echo 'Test override' && OUT="$TESTME"
	CHOICE="$OUT"
}

VideoDescription()
 {
	# Look up some key terms to create a video decription
	#	If video filename (lower cased) matches before ':',
	#	show string after ':' instead of file name
	local	line k v name
	local	vd='
Greg_Kerr:? Means a guess - have not verified

b2-2:Kamehameha Childhood Hideout?
b4-3:Golden Gate Bridge from San Francisco
396B_1105:Somewhere in Italy?
401c_1037:Ireland and Britain by Night from ISS?

CH_C007_C011:China West of Xi`an?
DB_D001_C005:Dubai Harbor?
LA_A006_C008:LAX
MEX_A006_C008:Republicans meeting in Mexico?
PA_A010_C007:Democarats meeting in PA?
TH_804_A001:Thailand (aka Paradise) Undersea?

A001_C004:Satellite over Namibia Maybe?
A005_C009:LA Freeway?
A006_C004:Hollywood Hills?
A007_C017:NYC Harbor?
A008_C004:Beach in LA for Baywatch?
A008_C007:Golden Gate Bridge from Marin County
A009_C001:Mars perhaps?
A010_C002:Kelp Farm California?
A011_C003:Nighttime in  Chicago?
A012_C014:San Francisco Harbor?
A012_C031:Undersea in the Caymans perhaps?
A013_C012:Golden Gate Bridge
A014_C008:Pink coral Australia?
A015_C018:Long Bridge at Night?
A016_C002:Kelp off the Coast?
A108_C001:Earth From ISS? 
A103_C002:Horn of Africa?
B005_C011:This should be night B005_C011?
C007_C004:Maybe Thailand or China?
C007_C004:Maybe China?
D011_C011:This is a test for D011_C011? 
G008_C015:Pinkish Trail through Mountains?
H004_C009:Cockpit view from some flight?
H004_C010:Coming over ridge to Hong Kong?
H012_C009:Beach at Sunset or Sunrise?
L001_C006:Desert West of Dubai?
L004_C011:London Bridge by Night
L007_C007:City Park Somewhere?
L012_C002:London At Dawn?
N008_C003:Manhattan from Staten Island?
N013_C004:Times Square, NYC, USA by Night?
U009_C004:Swimming with Sharks?
Y002_C013:Maybe Iceland or Colorado or Yosemite?
Y009_C015:Iceland Pink Forest?

1223LV_FL:Maybe Chicago?
GMT026:Korea and Japan at Night from Space?
GMT312:Africa at Night from Space?

arthursseat:Arthur`s Seat, Edinburgh, UK
big-sur:Big Sur, California
hampstead:London, UK from Hampstead
northstrip:Las Vegas Strip (North)
pecos_fog:Foggy Pecos, Texas, US
portland:Portland, Oregon, US
'
	ToLower "$1"; name="$OUT"
	OUT=$(echo "$vd" | while read line; do if [ -n "$line" ]; then
		v="${line#*:}"
		ToLower "${line%%:*}"; k="$OUT"
		[ "${name#*$k}" != "$name" ] && echo "$v"
	fi; done)
	[ -z "$OUT" ] && OUT="$1"
 }

ToLower()
 {
#	[ -n "$BASH_VERSINFO" ] && [ $BASH_VERSINFO -gt 3 ] && OUT="${1,,*}" && return
	OUT=$(echo "$1" | tr '[:upper:]' '[:lower:]')
 }

Subtitles()
 {
	local	t u n s f c g

	f="+%H:%M, %A, %d. %B"
	case "$OS_TYPE" in
	  'FreeBSD')	c='-v+'	;;	# FreeBSD Date increment
	  *)			c='-d@'	;;	# NetBSD/Linux Date format and 
	esac
	t=0; n=1
	s=$(date +%s)
	while [ $t -lt 20 -a $n -lt 20 ]; do
		u="${t}"
		[ ${#u} -eq 1 ] && u="0$u"
		[ "${c%@}" = "$c" ] && g="${c}${t}M" || g="${c}${s}"
		g=$(date "$g" "$f")
		echo "$n
00:$u:03,142 --> 00:$u:09,067
$g
$1
"
		t=$(($t + $SUBTIME))
		n=$((1 + $n))	# In case some joker makes SUBTIME 0
		s=$((60 * $SUBTIME + $s))
	done
	[ $TEST -ne 0 ] && echo "Date Parameters: [$g][$f]" >&2
 }

Abort()
 {
	if [ $MPID -ne 0 ]; then
		echo "Abort: $MPID" >> /tmp/aerial.$(id -un).out
		kill $MPID
		MPID=0
		exit 66
	fi
 }

# this part taken from Kevin Cox
# https://github.com/kevincox/xscreensaver-videos

trap Abort TERM INT HUP
while [ 1 -eq 1 ]; do
	Choose
	# Create SUBTITLE blurp at 0,5,10,15 minutes
	st="${CHOICE##*/}"
	st="${st%%.*}"

	VideoDescription "$st"; st="$OUT"
	Subtitles "$st" > "$SUBTITLE"

	if [ $TEST -ne 0 ]; then
		head -n 10 "$SUBTITLE"
		echo "Choice:	$CHOICE"
		ls -lh "$CHOICE"
		exit 1
	elif [ -s "$CHOICE" ]; then
		# file is on filesystem so just play it
		echo "Local: $CHOICE" > /tmp/aerial.$(id -un).out
		mplayer -nosound -really-quiet -nolirc -nostop-xscreensaver -wid "$XSCREENSAVER_WINDOW" -fs "$CHOICE" -sub "$SUBTITLE" >> /tmp/aerial.$(id -un).out 2>&1 &
	    MPID=$!
	elif [ $ONLINE -ne 0 ]; then
		# no file on filesystem so try to stream it
		echo "Streaming: $CHOICE" > /tmp/aerial.$(id -un).out
		mplayer -nosound -really-quiet -nolirc -nostop-xscreensaver -wid "$XSCREENSAVER_WINDOW" -fs "$APPLEURL/$CHOICE" -sub "$SUBTITLE" >> /tmp/aerial.$(id -un).out 2>&1  &
		MPID=$!
	else
		echo "*** $MOVIES is empty and ONLINE is off ***"
		exit 99
	fi
	wait $MPID
	sleep 3	# Sometimes PID hangs around after death
	[ $? -gt 128 ] && { echo "Killing: $MPID" >> /tmp/aerial.$(id -un).out; kill $MPID ; exit 121; }
done
