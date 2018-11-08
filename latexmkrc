#!/usr/bin/perl
$latex = 'uplatex -synctex=1 -halt-on-error -shell-escape';
$latex_silent = 'uplatex -synctex=1 -halt-on-error -interaction=batchmode';
$bibtex = 'pbibtex';
$biber  = 'biber --bblencoding=utf8 -u -U --output_safechars';
$dvipdf = 'dvipdfmx %O -o %D %S';
$makeindex = 'mendex %O -o %D %S';
$max_repeat = 10;
$pdf_mode = 3; # use dvipdfmx
$pvc_view_file_via_temporary = 0;
$pdf_previewer = "open -ga /Applications/Skim.app";
