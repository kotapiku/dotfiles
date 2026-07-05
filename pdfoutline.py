# pdfoutline.py in.pdf in.toc offset out.pdf
# https://www.planetpdf.com/planetpdf/pdfs/primer.pdf
# https://www.adobe.com/content/dam/acom/en/devnet/acrobat/pdfs/pdfmarkreference.pdf

import sys
import re
import subprocess

class Entry():
    def __init__(self, name, page, children):
        self.name = name
        self.page = page
        self.children = children # Entry list

def toc_to_elist(toc, TAB = '    '):
    lines = list(filter(bool, toc.split('\n'))) # filter empty string
    cur_entry = [[]] # current entries by depth
    for line in lines:
        depth = line.count(TAB)
        pagestr = re.findall(r'\d+$', line)[0]
        page = int(pagestr)
        name = line[depth * len(TAB):-(len(pagestr)+1)]

        cur_entry = cur_entry[:depth+1] + [[]]
        cur_entry[depth].append(Entry(name, page, cur_entry[depth+1]))
    return cur_entry[0]


# distructive
def offset_elist(elist, offset):
    for entry in elist:
        entry.page += offset
        offset_elist(entry.children, offset)

def elist_to_gs(elist):
    def pdfmark_string(value):
        return '<%s>' % ('\ufeff' + value).encode('utf-16-be').hex().upper()

    def rec_elist_to_gslist(elist):
        gs_list = []
        for entry in elist:
            gs_list.append("[/Page %d /View [/XYZ null null null] /Title %s /Count %d /OUT pdfmark" \
                    % (entry.page, pdfmark_string(entry.name), len(entry.children)))
            gs_list += rec_elist_to_gslist(entry.children)
        return gs_list
    return '\n'.join(rec_elist_to_gslist(elist))

def test():
    toc = \
'''
foo0 4
foo1 5
    buz 7
    buzz 8
        buzzz9
    boo 10
foo2 12
    yamm 20
        yaam 30
            yo 40
    yeah 5
foo3 3
'''
    elist =toc_to_elist(toc)
    print("toc_to_elist: " + str(elist[2].children[0].page == 20))
    offset_elist(elist, 3)
    print("offset_elist: " + str(elist[2].children[0].page == 23))


if __name__ == '__main__':
    if len(sys.argv) != 5:
        print('usage: pdfoutline in.pdf in.toc offset out.pdf')
        exit(1)
    inpdf = sys.argv[1]
    toc_filename = sys.argv[2]
    offset = int(sys.argv[3])
    outpdf = sys.argv[4]

    with open(toc_filename, encoding='utf-8') as f:
        toc = f.read()

    elist = toc_to_elist(toc)
    offset_elist(elist, offset)
    gs_command = elist_to_gs(elist)

    with open('/tmp/tmp.gs', 'w') as out:
        out.write(gs_command)
    subprocess.run(
        ['gs', '-o', outpdf, '-sDEVICE=pdfwrite', '/tmp/tmp.gs' , '-f', inpdf])
