import get_file_structure as fs
import file_read as fr
import file_generate as fg
import urllib3
import textgenrnn

http = urllib3.PoolManager()
main_url = 'https://www.mutopiaproject.org/'
cat_url = 'https://www.mutopiaproject.org/cgibin/'

style_files = fs.get_styles_list(http, main_url, cat_url, 'midi')
source_files = fr.read_midi_files('Song', style_files, http)

##textgen = textgenrnn.textgenrnn()

##fg.generate_file(textgen, ly_files)


