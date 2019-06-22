import get_file_structure as fs
import file_operations as fo
##import file_generate as fg
import generate_music as gm
import urllib3
import json
import numpy as np

http = urllib3.PoolManager()
main_url = 'https://www.mutopiaproject.org/'
cat_url = 'https://www.mutopiaproject.org/cgibin/'

seq_length = 10


## if file list hasn't been saved on disk:
"""
style_files = fs.get_styles_list(http, main_url, cat_url, 'midi')

with open('files_list.json','w') as save_file:
    ##for style, url_addr in style_files.items():
    json.dump(style_files, save_file, indent=4)
        ##save_file.write(style + ': ' + url_addr)
"""

## else read file structure from file
with open('files_list.json','r') as save_file:
    style_files = json.load(save_file)

## read MIDI files for given style
source_files = fo.read_midi_files('March', style_files, http)

## just for testing - read one midi
# time_sign, tempo, whole_note = fo.get_piece_info(source_files['TransitOfVenus.mid'])
# notes = fo.get_note_seqs(source_files['TransitOfVenus.mid'], whole_note)

rhythm_list, rev_dict, rhythm_dict = gm.make_rhythm_dict()
# generate network
notes_model, rhythm_model, num_steps = gm.create_networks(num_steps=5)

for file in source_files:
    time_sign, tempo, whole_note = fo.get_piece_info(source_files[file])
    notes = fo.get_note_seqs(source_files[file], whole_note, rhythm_list)
    print('File ' + file + ' read succesfully!\n')

    # run network to create new music piece
    for staff in notes:
        notes_prediction, rhythm_prediction, generated = gm.run_networks(
                                                        notes_model, rhythm_model,
                                                        notes[staff], rhythm_dict, iterations=seq_length,
                                                        num_steps=5, num_epochs=5)

        print(generated)

## write output to MIDI file
#fo.write_midi_file(notes[:,0], notes[:,1], tempo, whole_note, time_sign)
