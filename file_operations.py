import urllib3
import mido
import os
import numpy as np
from random import uniform as rand_uniform
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
            os.remove('tempmid')
            midi_files[name] = mfile
    return midi_files


def write_midi_file(note_tracks, tempo_bpm, whole_note, time_sign=(4,4), file_name='new_piece.mid'):
    mfile = mido.MidiFile(ticks_per_beat=int(whole_note/4))
    ctrack = mido.MidiTrack()
    ctrack.append(mido.MetaMessage('track_name', name='control track'))
    ctrack.append(mido.MetaMessage('time_signature', numerator=int(time_sign[0]), denominator=int(time_sign[1])))
    ctrack.append(mido.MetaMessage('set_tempo', tempo=int(mido.bpm2tempo(tempo_bpm))))
    ctrack.append(mido.MetaMessage('end_of_track'))
    mfile.tracks.append(ctrack)
    for t in note_tracks:
        notes = note_tracks[t]
        track = mido.MidiTrack()
        track.append(mido.MetaMessage('track_name', name='track '+t))
        track.append(mido.Message('program_change'))
        for note_no, duration in zip(notes[:,0], notes[:,1]):
            if duration > 0:
                vel = [int(rand_uniform(65,127)), int(rand_uniform(65,127))]
                track.append(mido.Message('note_on',  note=note_no, velocity=vel[0], time=int(0)))
                track.append(mido.Message('note_off', note=note_no, velocity=vel[1], time=int(duration*whole_note)))
        track.append(mido.MetaMessage('end_of_track', time=int(0)))
        mfile.tracks.append(track)
    if not os.path.isfile(file_name): os.mknod(file_name)
    mfile.save(file_name)

def get_piece_info(mfile):
    whole_note = mfile.ticks_per_beat * 4
    time_sign = None
    tempo = None
    for msg in mfile.tracks[0]:
        if msg.is_meta:
            if msg.type == 'time_signature':
                time_sign = (msg.numerator, msg.denominator)
            elif msg.type == 'set_tempo':
                tempo = round(mido.tempo2bpm(msg.tempo))
    if time_sign == None: time_sign=(4, 4)
    if tempo == None: tempo = 500000
    return time_sign, tempo, whole_note


def get_note_seqs(mfile, whole_note, rhythm_list):
    notes = {}
    for track in mfile.tracks[1:]:
        track_notes = []
        notes_on = []
        times = []
        for msg in track:
        #queue for checking which note is on and their durations
            if ( msg.type == 'note_on' and msg.velocity >= 1 ):
                notes_on.append(msg.note)
                times.append(msg.time)
            elif (
                    ( msg.type == 'note_off'
                     or (msg.type == 'note_on' and msg.velocity < 1)
                    )
                 and msg.note in notes_on
                 ):
                if msg.time == 0:
                    duration = track_notes[-1][1]
                else:
                    #duration as a quotient of the whole note
                    duration = (msg.time - times.pop(notes_on.index(msg.note))) / whole_note
                if duration < 0 and msg.time > 0: duration = msg.time / whole_note
                if duration not in rhythm_list:
                    duration = rhythm_list[np.argmin(np.abs(rhythm_list-duration))]
                track_notes.append((int(msg.note), duration))
                notes_on.remove(msg.note)
        if len(track_notes) > 0:
            notes[track.name] = np.array(track_notes)
    return notes
