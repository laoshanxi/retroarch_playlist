#!/bin/bash
# modify from /emuelec/scripts/emuelecRunEmu.sh

# Usage
# sh getEmuCore.sh -P atari2600 --core=stella  --emulator=libretro
# -P 			platform name
# --core 		core name
# --emulator 	emulator name
. /etc/profile

arguments="$@"

# Set the variables
CFG="/storage/.emulationstation/es_settings.cfg"
LOGEMU="No"
VERBOSE=""
LOGSDIR="/emuelec/logs"
EMUELECLOG="$LOGSDIR/emuelec.log"
TBASH="/usr/bin/bash"
JSLISTENCONF="/emuelec/configs/jslisten.cfg"
RATMPCONF="/tmp/retroarch/ee_retroarch.cfg"
RATMPCONF="/storage/.config/retroarch/retroarch.cfg"
NETPLAY="No"

# Extract the platform name from the arguments
PLATFORM="${arguments##*-P}" # read from -P onwards
PLATFORM="${PLATFORM%% *}"   # until a space is found

CORE="${arguments##*--core=}"         # read from --core= onwards
CORE="${CORE%% *}"                    # until a space is found
EMULATOR="${arguments##*--emulator=}" # read from --emulator= onwards
EMULATOR="${EMULATOR%% *}"            # until a space is found

ROMNAME="$1"
DIRNAME=$(dirname "$ROMNAME")
BASEROMNAME=${ROMNAME##*/}
ROMNAMETMP=${ROMNAME%.*}

if [[ $EMULATOR = "libretro" ]]; then
	EMU="${CORE}_libretro"
	LIBRETRO="yes"
else
	EMU="${CORE}"
fi

TXT_CORE_PATH="/tmp/TXT_CORE_PATH"
rm -f ${TXT_CORE_PATH}

[[ ${PLATFORM} = "ports" ]] && LIBRETRO="yes"

KILLDEV=${ee_evdev}
KILLTHIS="none"

# if there wasn't a --NOLOG included in the arguments, enable the emulator log output. TODO: this should be handled in ES menu
if [[ $arguments != *"--NOLOG"* ]]; then
	LOGEMU="Yes"
	VERBOSE="-v"
fi

set_kill_keys() {
	TESTE=0
}

if [ -z ${LIBRETRO} ]; then

	# Read the first argument in order to set the right emulator
	case ${PLATFORM} in
	"atari2600")
		if [ "$EMU" = "STELLASA" ]; then
			set_kill_keys "stella"
			RUNTHIS='nice -n -19 ${TBASH} /usr/bin/stella.sh "${ROMNAME}"'
		fi
		;;
	"atarist")
		if [ "$EMU" = "HATARISA" ]; then
			set_kill_keys "hatari"
			RUNTHIS='nice -n -19 ${TBASH} /usr/bin/hatari.start "${ROMNAME}"'
		fi
		;;
	"openbor")
		set_kill_keys "OpenBOR"
		RUNTHIS='nice -n -19 ${TBASH} /usr/bin/openbor.sh "${ROMNAME}"'
		;;
	"setup")
		[[ "$EE_DEVICE" == "OdroidGoAdvance" ]] && set_kill_keys "kmscon" || set_kill_keys "fbterm"
		RUNTHIS='nice -n -19 ${TBASH} /emuelec/scripts/fbterm.sh "${ROMNAME}"'
		EMUELECLOG="$LOGSDIR/ee_script.log"
		;;
	"dreamcast")
		if [ "$EMU" = "REICASTSA" ]; then
			set_kill_keys "reicast"
			sed -i "s|REICASTBIN=.*|REICASTBIN=\"/usr/bin/reicast\"|" /emuelec/bin/reicast.sh
			RUNTHIS='nice -n -19 ${TBASH} /emuelec/bin/reicast.sh "${ROMNAME}"'
			LOGEMU="No" # ReicastSA outputs a LOT of text, only enable for debugging.
			cp -rf /storage/.config/reicast/emu_new.cfg /storage/.config/reicast/emu.cfg
		fi
		if [ "$EMU" = "REICASTSA_OLD" ]; then
			set_kill_keys "reicast_old"
			sed -i "s|REICASTBIN=.*|REICASTBIN=\"/usr/bin/reicast_old\"|" /emuelec/bin/reicast.sh
			RUNTHIS='nice -n -19 ${TBASH} /emuelec/bin/reicast.sh "${ROMNAME}"'
			LOGEMU="No" # ReicastSA outputs a LOT of text, only enable for debugging.
			cp -rf /storage/.config/reicast/emu_old.cfg /storage/.config/reicast/emu.cfg
		fi
		;;
	"mame" | "arcade" | "capcom" | "pgm" | "cps1" | "cps2" | "cps3")
		if [ "$EMU" = "AdvanceMame" ]; then
			set_kill_keys "advmame"
			RUNTHIS='nice -n -19 ${TBASH} /usr/bin/advmame.sh "${ROMNAME}"'
		fi
		;;
	"nds")
		set_kill_keys "drastic"
		RUNTHIS='nice -n -19 ${TBASH} /storage/.emulationstation/scripts/drastic.sh "${ROMNAME}"'
		;;
	"n64")
		if [ "$EMU" = "M64P" ]; then
			set_kill_keys "mupen64plus"
			RUNTHIS='nice -n -19 ${TBASH} /usr/bin/m64p.sh "${ROMNAME}"'
		fi
		;;
	"amiga" | "amigacd32")
		if [ "$EMU" = "AMIBERRY" ]; then
			RUNTHIS='nice -n -19 ${TBASH} /usr/bin/amiberry.start "${ROMNAME}"'
		fi
		;;
	"residualvm")
		if [[ "${ROMNAME}" == *".sh" ]]; then
			set_kill_keys "fbterm"
			RUNTHIS='nice -n -19 ${TBASH} /emuelec/scripts/fbterm.sh "${ROMNAME}"'
			EMUELECLOG="$LOGSDIR/ee_script.log"
		else
			set_kill_keys "residualvm"
			RUNTHIS='nice -n -19 ${TBASH} /usr/bin/residualvm.sh sa "${ROMNAME}"'
		fi
		;;
	"scummvm")
		if [[ "${ROMNAME}" == *".sh" ]]; then
			set_kill_keys "fbterm"
			RUNTHIS='nice -n -19 ${TBASH} /emuelec/scripts/fbterm.sh "${ROMNAME}"'
			EMUELECLOG="$LOGSDIR/ee_script.log"
		else
			if [ "$EMU" = "SCUMMVMSA" ]; then
				set_kill_keys "scummvm"
				RUNTHIS='nice -n -19 ${TBASH} /usr/bin/scummvm.start sa "${ROMNAME}"'
			else
				RUNTHIS='nice -n -19 ${TBASH} /usr/bin/scummvm.start libretro'
			fi
		fi
		;;
	"daphne")
		if [ "$EMU" = "HYPSEUS" ]; then
			set_kill_keys "hypseus"
			RUNTHIS='nice -n -19 ${TBASH} /storage/.config/emuelec/scripts/hypseus.start.sh "${ROMNAME}"'
		fi
		;;
	"pc")
		if [ "$EMU" = "DOSBOXSDL2" ]; then
			set_kill_keys "dosbox"
			RUNTHIS='nice -n -19 ${TBASH} /usr/bin/dosbox.start "${ROMNAME}"'
		fi
		if [ "$EMU" = "DOSBOX-X" ]; then
			set_kill_keys "dosbox-x"
			RUNTHIS='nice -n -19 ${TBASH} /usr/bin/dosbox-x.start "${ROMNAME}"'
		fi
		;;
	"psp" | "pspminis")
		if [ "$EMU" = "PPSSPP351" ]; then
			set_kill_keys "PPSSPP351"
			RUNTHIS='nice -n -19 ${TBASH} /usr/bin/ppsspp351.sh "${ROMNAME}"'
		fi
		if [ "$EMU" = "PPSSPPSDL" ]; then
			set_kill_keys "PPSSPPSDL"
			RUNTHIS='nice -n -19 ${TBASH} /usr/bin/ppsspp.sh "${ROMNAME}"'
		fi
		;;
	"neocd")
		if [ "$EMU" = "fbneo" ]; then
			RUNTHIS='nice -n -19 /usr/bin/retroarch $VERBOSE -L /tmp/cores/fbneo_libretro.so --subsystem neocd --config ${RATMPCONF} "${ROMNAME}"'
		fi
		;;
	"mplayer")
		set_kill_keys "${EMU}"
		RUNTHIS='nice -n -19 ${TBASH} /emuelec/scripts/fbterm.sh mplayer_video "${ROMNAME}" "${EMU}"'
		;;
	"pico8")
		set_kill_keys "pico8_dyn"
		RUNTHIS='nice -n -19 ${TBASH} /emuelec/scripts/pico8.sh "${ROMNAME}"'
		;;
	"onscripter")
		set_kill_keys "onscripter"
		RUNTHIS='nice -n -19 ${TBASH} /usr/bin/onscripter.sh "${DIRNAME}"'
		;;
	esac
else
	# We are running a Libretro emulator set all the settings that we chose on ES

	if [[ ${PLATFORM} == "ports" ]]; then
		PORTCORE="${arguments##*-C}"    # read from -C onwards
		EMU="${PORTCORE%% *}_libretro"  # until a space is found
		PORTSCRIPT="${arguments##*-SC}" # read from -SC onwards
	fi

	RUNTHIS='nice -n -19 /usr/bin/retroarch $VERBOSE -L /tmp/cores/${EMU}.so --config ${RATMPCONF} "${ROMNAME}"'

	CORE_PATH="/tmp/cores/${EMU}.so"
	if [ -f ${CORE_PATH} ]; then
		echo ${CORE_PATH} >${TXT_CORE_PATH}
		# echo "Checking core <${CORE_PATH}>"
	else
		echo "not exist: ${CORE_PATH}"
	fi

fi
