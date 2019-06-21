import urllib3
import mido
import os
import numpy

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
            
def get_piece_info(mfile):
    for msg in mfile.tracks[0]:
        if msg.is_meta:
            if msg.type == 'time_signature':
                time_sign = (msg.numerator, msg.denominator)
                whole_note = msg.clocks_per_click / 4
            elif msg.type == 'set_tempo':
                tempo = round(mido.tempo2bpm(msg.tempo))
    return time_sign, tempo, whole_note
            
            
def get_note_seqs(mfile, whole_note):
    notes = {}
    for track in mfile.tracks:
        if track.name != 'control track':
            track_notes = []
            notes_on = []
            times = []
            for msg in track:
            #queue for checking which note is on and their durations
                if msg.type == 'note_on':
                    notes_on.append(msg.note)
                    times.append(msg.time)
                elif msg.type == 'note_off':
                    if msg.note in notes_on:
                        #duration in N, where 1/N is a quotient of the whole note
                        duration = (msg.time - times.pop(notes_on.index(msg.note))) / whole_note
                        track_notes.append((msg.note, duration))
                        notes_on.remove(msg.note)
            notes[track.name] = numpy.array(track_notes)
    return notes
