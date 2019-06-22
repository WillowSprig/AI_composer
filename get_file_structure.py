import urllib3
import re
"""
main_url = 'https://www.mutopiaproject.org/'
cat_url = 'https://www.mutopiaproject.org/cgibin/'
"""
ftypes = {'ly': 'ly file',
          'midi': 'mid file'}

def get_styles_list(http, main_url, cat_url, ftype):
    response = http.request('GET', main_url)
    page = response.data.decode('utf-8')
    style_lines = page.split('-- Styles --')[1].split('-- Collections --')[0].splitlines()
    style_addresses = dict()

    for line in style_lines:
        if 'a href' in line:
            style_name = line.split('\'>')[1].split('</a>')[0]
            style_addresses[style_name] = main_url + line.split('a href=\'')[1].split('\'')[0]

    style_files = dict()
    for style in style_addresses:
        style_page = http.request('GET', style_addresses[style]).data.decode('utf-8')
        style_files[style] = get_files_list(ftype, style_page, [], http, cat_url)
    return style_files


def get_files_list(ftype, style_page, curr_style_files, http, cat_url):
    ftypen = ftypes[ftype]
    start_idx = 0
    for nfile in re.finditer(ftypen, style_page):
        end_idx = nfile.start()
        curr_style_files.append( style_page[ start_idx:end_idx ].split('a href=\"')[-1].split('\"')[0] )
        start_idx = nfile.end()
    isnext = style_page.rfind('Next 10')
    if isnext != -1:
        next_page = style_page[isnext-300:isnext-1].split('a href=\"')[-1]
        page_content = http.request('GET', cat_url + next_page).data.decode('utf-8')
        get_files_list(ftype, page_content, curr_style_files, http, cat_url)
    return curr_style_files
