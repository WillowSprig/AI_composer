import urllib3
import mido
import os

#http = urllib3.PoolManager()

def load_MIDI_table(MIDI_conv):
    notes = dict()
    
    with open(MIDI_conv) as file:
        for line in file:
            number, name  = line.split(' ',1)
            names = list(name.split())
            notes[number] = names
    return notes

            
def read_ly_files(style, style_files, http):
    files_content = list()
    
    for file in style_files[style]:
        if '.ly' in file:
            file_content = http.request('GET', file).data.decode('utf-8')
            files_content.append(file_content)
    return files_content
    
def read_midi_files(style, style_files, http):
    midi_files = {}
    
    for file in style_files[style]:
        if '.mid' in file:
            name = file.rsplit('/',1)[1]
            file_content = http.request('GET', file).data
            with open('tempmid','wb') as temp_file:
                temp_file.write(file_content)
            mfile = mido.MidiFile('tempmid')
            print('File ' + name + ' processed succesfully!\n')
            os.remove('tempmid')
            midi_files[name] = mfile
    return midi_files
            

