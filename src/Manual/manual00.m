\"      This set of mm macro commands defines a book-like format.
\"      The usual headings, H1 to H4, are used, but the results are
\"      as follows.
\"      .H 1 indicates a chapter heading.  Each chapter starts on a new
\"      page, a large chapter heading is printed, and the chapter heading
\"      becomes the running heading.
\"      .H 2 starts a new page.
\"      Lower level headings are simply in boldface, and become smaller
\"      in size as heading level decreases.
\"
\"      Page numbers are of the form "chapter-page".  No page numbers
\"      appear until the first heading is printed.
\"
\"      No title page is produced by these commands.
\"                                      J. Nagle   December, 1980
\"                                      Macro version 2.4 of 3/7/86
\"
.nr Hc 0                \" All headings are left-justified
.nr Hb 7                \" Break after all headings
.nr Hs 7                \" Space after all headings
.nr Hu 1                \" Heading level for HU
.nr Cl 7                \" Save all headings for table of contents
.nr Pt 0                \" Block style of paragraphs
.ds HF 3 3 3 3 3 3 3    \" All headings in boldface
.SA 1                   \" Right justify
.nr Ej 0                \" Page ejects will be handled in escape macros
.de DP                  \" DP displays are for representing computer programs
.DS
.ps -1p			\" Drop point size one point
.ft L                   \" DP displays are non-filled monospace
..
.de HX                  \" Before-heading user processing
.\"tms commented out
.\"tm "    BEFORE: \\n(.s PT"
.ds }0                  \" no automatic heading mark
.if \\$1=1 \{           \" H 1 - chapter heading, 2 lines on new page
.PH " "                 \" cancel outstanding page heading
.rs                     \" force spacing to work
.bp                     \" start new page
.nr P 1                 \" reset page number
.ps 14p                 \" will print "Chapter N" in 14 point
.sp 2                   \" skip two lines
.B "Chapter \\n(H1"     \" print "Chapter N"
.ps                     \" pop point size
.sp 24p                 \" two blank lines
.PH "''\\$3''"          \" chapter title becomes running heading
.ps 22p\}               \" chapter title in 22 point
.if \\$1=2 \{\
.bp                     \" H 2 - new page
.ps 18p\}
.if \\$1=3 .ps 16p      \" H 3 - 14-point headings
.if \\$1>3 .ps 14p      \" H 4 and below - 12-point headings
.vs \\n(.s+2p           \" set vertical spacing 2 pts above type size
.\"tm "HEADING \\$1, \\n(.s PT: \\$3"
..
.de HZ                  \" After-heading user processing
.ps \\n(:Pp             \" Back to previous point size
.vs \\n(.sp+2p          \" Back to previous vertical size
.if \\$1=1 \{           \" chapter heading handling
.sp 96p                 \" white space after chapter heading
.PF "''\\n(H1\-\\\\\\\\nP\ \ 'Communications Corporation'"
.EF "'''\(fs Ford Aerospace &'"
.OF "'''\(fs Ford Aerospace &'"\}
.\"tm "     AFTER: \\n(.s PT"
..
.PH " "
.PF " "
.S 12
.\"tm "POINT SIZE AT START = \n(.s "
