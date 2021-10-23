#!/usr/bin/python3
import os
import json
import traceback
import logging
import xml.dom.minidom
from shutil import copyfile

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

COPY_RA_IMAGE = True  # set to False if you do not need title image, this will cost extra disk space
RA_PLAY_LIST_DIR = "/storage/playlists"
ES_CFG_FILE = "/storage/.config/emulationstation/es_systems.cfg"
ES_GAME_LIST_FILE_NAME = "gamelist.xml"
GET_CORE_SHELL_FILE = "getcore.sh"
TEMP_CORE_SHELL_OUTPUT_FILE = "/tmp/TXT_CORE_PATH"


class es_core_obj:
    def __init__(self) -> None:
        self.name = ""
        self.path = ""
        self.extension = ""
        self.platform = ""
        self.core_path = ""
        self.core_name = ""


class game_obj:
    def __init__(self) -> None:
        self.path = ""
        self.label = ""
        # self.core_path = ""
        # self.core_name = ""
        # self.crc32 = ""
        self.db_name = ""
        # self.image = ""


class gamelist_obj:
    def __init__(self) -> None:
        self.version = "1.4"
        self.default_core_path = ""
        self.default_core_name = ""
        self.label_display_mode = 0
        self.right_thumbnail_mode = 0
        self.left_thumbnail_mode = 0
        self.sort_mode = 0
        self.items = []


RETRO_ARCH_LIST = gamelist_obj()


def mkdir(path):
    folder = os.path.exists(path)
    if not folder:
        os.makedirs(path)


def read_xml(file_name):
    with open(file_name, "rb") as file:
        file_content = bytes.decode(file.read())
        return xml.dom.minidom.parseString(file_content)


def read_es_config():
    # parse es_systems.cfg to find core and emu mapping
    # dom = xml.dom.minidom.parse(ES_CFG_FILE)
    dom = read_xml(ES_CFG_FILE)
    systemList = dom.documentElement
    systems = systemList.getElementsByTagName("system")

    logger.info("Total ES systems : %d" % len(systems))
    # os.system("rm -f /storage/playlist/*.lpl")
    for system in systems:
        if len(system.getElementsByTagName("emulators")):
            emulaters = system.getElementsByTagName("emulators")[0]
            emulator = None
            emulator_core = None
            for emu in emulaters.getElementsByTagName("emulator"):
                if len(emu.getElementsByTagName("cores")) > 0 and len(emu.getElementsByTagName("cores")[0].getElementsByTagName("core")) > 0:
                    core = emu.getElementsByTagName("cores")[0].getElementsByTagName("core")[0]
                    if emulator is None:
                        emulator = emu
                        emulator_core = core
                    elif core and core.hasAttribute("default") and core.getAttribute("default") == "true":
                        # print("default core")
                        emulator = emu
                        emulator_core = core
                        break

            platform = system.getElementsByTagName("platform")[0].childNodes[0].data
            emulator_name = emulator.getAttribute("name")
            core_name = emulator_core.childNodes[0].data

            name = system.getElementsByTagName("name")[0].childNodes[0].data
            path = system.getElementsByTagName("path")[0].childNodes[0].data
            extension = system.getElementsByTagName("extension")[0].childNodes[0].data

            args = "-P {0} --core={1} --emulator={2}".format(platform, core_name, emulator_name)
            # print(args)
            os.system("sh {0} {1}".format(GET_CORE_SHELL_FILE, args))
            if os.path.exists(TEMP_CORE_SHELL_OUTPUT_FILE):
                with open(TEMP_CORE_SHELL_OUTPUT_FILE, "r", encoding="utf-8") as f:
                    core_path = f.readline()
                    if not core_path:
                        break
                    core_path = core_path.rstrip("\n")
                    # print(core_path)
                    core = es_core_obj()
                    core.name = name
                    core.path = path
                    core.extension = extension
                    core.core_name = core_name
                    core.core_path = core_path
                    # system_cores[name] = core
                    game_list, playlist_file_name = read_gamelist(core)
                    write_ra_playlist(game_list, playlist_file_name)


def read_gamelist(core):
    # core = es_core_obj()
    try:
        es_gamelist_full_path = os.path.join(core.path, ES_GAME_LIST_FILE_NAME)
        ra_playlist_name = core.name + ".lpl"

        RETRO_ARCH_LIST = gamelist_obj()
        RETRO_ARCH_LIST.default_core_name = core.core_name
        RETRO_ARCH_LIST.default_core_path = core.core_path
        if os.path.exists(es_gamelist_full_path):
            logger.debug("Reading ES game list file <%s>" % es_gamelist_full_path)
            # ra_boxarts_path = "/storage/thumbnails/" + core.name + "/Named_Boxarts"
            ra_titles_path = "/storage/thumbnails/" + core.name + "/Named_Titles"
            # ra_snaps_path = "/storage/thumbnails/" + core.name + "/Named_Snaps"
            if COPY_RA_IMAGE:
                # mkdir(ra_boxarts_path)
                mkdir(ra_titles_path)
                # mkdir(ra_snaps_path)
            dom = read_xml(es_gamelist_full_path)
            gameList = dom.documentElement
            for game_element in gameList.getElementsByTagName("game"):
                game_path = game_element.getElementsByTagName("path")[0].childNodes[0].data
                game_name = game_element.getElementsByTagName("name")[0].childNodes[0].data
                game_image = (
                    game_element.getElementsByTagName("image")[0].childNodes[0].data if len(game_element.getElementsByTagName("image")) > 0 else ""
                )
                game = game_obj()
                es_image_path = os.path.join(core.path, game_image.lstrip("./"))
                game.path = os.path.join(core.path, game_path.lstrip("./"))
                game.db_name = ra_playlist_name
                game.label = game_name
                if COPY_RA_IMAGE and os.path.exists(es_image_path):
                    try:
                        # copyfile(es_image_path, os.path.join(ra_boxarts_path, game_name) + ".png")
                        copyfile(es_image_path, os.path.join(ra_titles_path, game_name) + ".png")
                        # copyfile(es_image_path, os.path.join(ra_snaps_path, game_name) + ".png")
                    except Exception:
                        pass
                RETRO_ARCH_LIST.items.append(game)
            return RETRO_ARCH_LIST, ra_playlist_name
    except Exception:
        logger.error("reading %s" % os.path.join(core.path, "gamelist.xml"))
        traceback.print_exc()
    return None, None


def write_ra_playlist(game_list, playlist_file_name):
    # game_list = gamelist_obj()
    if game_list:
        write_file_path = os.path.join(RA_PLAY_LIST_DIR, playlist_file_name)
        logger.info("writing <{0}> roms to <{1}>".format(len(game_list.items), write_file_path))
        content = json.dumps(game_list, default=lambda obj: obj.__dict__, sort_keys=False, indent=2, ensure_ascii=False)
        with open(write_file_path, "w", encoding="utf-8") as file:
            file.write(content)


read_es_config()
