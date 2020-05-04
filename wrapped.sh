#!/bin/bash

python3 - $1 <<EOF
#!/usr/bin/env python3
#
#  Podcasts Export
#  ---------------
#  Douglas Watson, 2020, MIT License
#
#  Intended for use within an Automator workflow.
#
#  Receives a destination folder, finds Apple Podcasts episodes that have been
#  downloaded, then copies those files into a new folder giving them a more
#  descriptive name.

import os
import sys
import shutil
import urllib.parse
import sqlite3

SQL = """
SELECT p.ZAUTHOR, p.ZTITLE, e.ZTITLE, e.ZASSETURL
from ZMTEPISODE e 
join ZMTPODCAST p
    on e.ZPODCASTUUID = p.ZUUID 
where ZASSETURL NOTNULL;
"""


def check_imports():
    """ Prompts for password to install dependencies, if needed """
    try:
        import mutagen
    except ImportError:
        os.system(
            """osascript -e 'do shell script "/usr/bin/pip3 install mutagen" with administrator privileges'""")


def get_downloaded_episodes(db_path):
    return sqlite3.connect(db_path).execute(SQL).fetchall()


def main(db_path, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    for author, podcast, title, path in get_downloaded_episodes(db_path):
        dest_path = os.path.join(output_dir,
                                 u"{}-{}-{}.mp3".format(author, podcast, title))
        shutil.copy(urllib.parse.unquote(path[len('file://'):]), dest_path)

        print(author)

        mp3 = MP3(dest_path, ID3=EasyID3)
        if mp3.tags is None:
            mp3.add_tags()
        mp3.tags['artist'] = author
        mp3.tags['album'] = podcast
        mp3.tags['title'] = title
        mp3.save()


if __name__ == "__main__":
    if len(sys.argv) <= 1:
        sys.stderr.write("No output folder specified\n")
        sys.exit(1)
    output_dir = sys.argv[1]
    db_path = os.path.expanduser(
        "~/Library/Group Containers/243LU875E5.groups.com.apple.podcasts/Documents/MTLibrary.sqlite")

    check_imports()
    from mutagen.mp3 import MP3
    from mutagen.easyid3 import EasyID3

    main(db_path, output_dir)

EOF