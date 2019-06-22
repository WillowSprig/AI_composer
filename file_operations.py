import urllib3
import mido
import os
import numpy
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
            print('File ' + name + ' processed succesfully!\n')
            os.remove('tempmid')
            midi_files[name] = mfile
    return midi_files


def write_midi_file(note_tracks, time_sign, tempo_bpm, whole_note, file_name='new_piece.mid'):
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
    for msg in mfile.tracks[0]:
        if msg.is_meta:
            if msg.type == 'time_signature':
                time_sign = (msg.numerator, msg.denominator)
            elif msg.type == 'set_tempo':
                tempo = round(mido.tempo2bpm(msg.tempo))
    return time_sign, tempo, whole_note


def get_note_seqs(mfile, whole_note, calculate_times=True):
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
                        #duration in 1/N, a quotient of the whole note
                        if msg.time == 0:
                            duraton = track_notes[-1][1]
                        else:
                            if calculate_times:
                                duration = (msg.time - times.pop(notes_on.index(msg.note))) / whole_note
                            else:
                                duration = msg.time
                        if duration>0: track_notes.append((int(msg.note), duration))
                        notes_on.remove(msg.note)
            notes[track.name] = numpy.array(track_notes)
    return notes
