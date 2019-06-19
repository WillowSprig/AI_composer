import urllib3

#http = urllib3.PoolManager()
#MIDI_conv = 'MIDI.txt'


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
        if '.mid' in file:
            file_content = http.request('GET', file).data.decode('utf-8')
            files_content.append(file_content)
    return files_content
            
##style_files = 
##read_ly_files('March', style_files)
