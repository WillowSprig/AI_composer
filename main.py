import get_file_structure as fs
import file_read as fr
##import file_generate as fg
import urllib3
##import textgenrnn

import json

http = urllib3.PoolManager()
main_url = 'https://www.mutopiaproject.org/'
cat_url = 'https://www.mutopiaproject.org/cgibin/'

"""
##if file list hasn't been saved on disk:
style_files = fs.get_styles_list(http, main_url, cat_url, 'midi')

with open('files_list.json','w') as save_file:
    ##for style, url_addr in style_files.items():
    json.dump(style_files, save_file, indent=4)
        ##save_file.write(style + ': ' + url_addr)
"""
     
style_files = json.load('files_list.json')

source_files = fr.read_midi_files('March', style_files, http)

##just for testing - read one midi
time_sign, tempo, whole_note = fr.get_piece_info(source_files['TransitOfVenus.mid'])
notes = fr.get_note_seqs(source_files['TransitOfVenus.mid'], whole_note)

##textgen = textgenrnn.textgenrnn()

##fg.generate_file(textgen, ly_files)


