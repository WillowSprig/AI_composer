import get_file_structure as fs
import file_operations as fo
##import file_generate as fg
import generate_music as gm
import urllib3
import json
import numpy as np
from os.path import isfile as file_exists

http = urllib3.PoolManager()
main_url = 'https://www.mutopiaproject.org/'
cat_url = 'https://www.mutopiaproject.org/cgibin/'


## if file list hasn't been saved on disk:
if not file_exists('files_list.json'):
    style_files = fs.get_styles_list(http, main_url, cat_url, 'midi')
    with open('files_list.json','w') as save_file:
        json.dump(style_files, save_file, indent=4)
## else read file structure from file
else:
    with open('files_list.json','r') as save_file:
        style_files = json.load(save_file)

# ask user about style
print('Choose music style:\n')
for num in enumerate(style_files.keys()): print(num)
style = list(style_files.keys())[int(input('Answer: '))]

## read MIDI files for given style
source_files = fo.read_midi_files(style, style_files, http)

# Choose file length
seq_length = abs(int(input('Choose file length (in notes): ')))
epochs = 200
steps = 5
hidden = 500

# generate list and dictionary of rhythm values
rhythm_list, rev_dict, rhythm_dict = gm.make_rhythm_dict()
# generate network
notes_model, rhythm_model, num_steps = gm.create_networks(num_steps=steps, hidden_size=hidden)

# Choose if for all or just one file
print('Do you want to generate music for one or all files?\n 0 - one, 1 - all\n')
ans = int(input('Answer: '))

if ans == 0:
    # choose file
    print('Choose file:\n')
    for num in enumerate(source_files.keys()): print(num)
    file = list(source_files.keys())[int(input('Answer: '))]
    time_sign, tempo, whole_note = fo.get_piece_info(source_files[file])
    notes = fo.get_note_seqs(source_files[file], whole_note, rhythm_list)
    print('File ' + file + ' read succesfully!\n')

    # run network to create new music piece
    generated_notes = {}
    for staff in notes:
        notes_prediction, rhythm_prediction, generated = gm.run_networks(
                                                        notes_model, rhythm_model,
                                                        notes[staff], rhythm_dict, iterations=seq_length,
                                                        num_steps=steps, num_epochs=epochs)
        generated_notes[staff] = generated

    ## write output to MIDI file
    fo.write_midi_file(generated_notes, tempo, whole_note, time_sign, 'LIKE_'+file)

elif ans == 1:
    for file in source_files:
        time_sign, tempo, whole_note = fo.get_piece_info(source_files[file])
        notes = fo.get_note_seqs(source_files[file], whole_note, rhythm_list)
        print('File ' + file + ' read succesfully!\n')

        # run network to create new music piece
        generated_notes = {}
        for staff in notes:
            notes_prediction, rhythm_prediction, generated = gm.run_networks(
                                                            notes_model, rhythm_model,
                                                            notes[staff], rhythm_dict, iterations=seq_length,
                                                            num_steps=steps, num_epochs=epochs)
            generated_notes[staff] = generated

        ## write output to MIDI file
        fo.write_midi_file(generated_notes, tempo, whole_note, time_sign, 'LIKE_'+file)
else:
    print('Sorry, wrong answer.')
