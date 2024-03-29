" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !get(g:, 'vimtex_syntax_enabled', 1)
  finish
endif

if !exists('b:current_syntax')
  let b:current_syntax = 'tex'
elseif b:current_syntax !=# 'tex'
  finish
endif

" Perform spell checking when there is no syntax
" - This will enable spell checking e.g. in toplevel of included files
syntax spell toplevel

" Increase default value of maxlines
syntax sync maxlines=500

scriptencoding utf-8

" {{{1 Improve handling of newcommand and newenvironment commands

" Allow arguments in newenvironments
syntax region texEnvName contained matchgroup=Delimiter
      \ start="{"rs=s+1  end="}"
      \ nextgroup=texEnvBgn,texEnvArgs contained skipwhite skipnl
syntax region texEnvArgs contained matchgroup=Delimiter
      \ start="\["rs=s+1 end="]"
      \ nextgroup=texEnvBgn,texEnvArgs
      \ skipwhite skipnl
syntax cluster texEnvGroup add=texDefParm,texNewEnv,texComment

" Add support for \renewcommand and \renewenvironment
syntax match texNewCmd "\\renewcommand\>"
      \ nextgroup=texCmdName skipwhite skipnl
syntax match texNewEnv "\\renewenvironment\>"
      \ nextgroup=texEnvName skipwhite skipnl

" Match nested DefParms
syntax match texDefParmNested contained "##\+\d\+"
highlight def link texDefParmNested Identifier
syntax cluster texEnvGroup add=texDefParmNested
syntax cluster texCmdGroup add=texDefParmNested

" }}}1
" {{{1 General match improvements

" More commands (e.g. from packages) take file arguments
syntax match texInputFile /\\includepdf\%(\[.\{-}\]\)\=\s*{.\{-}}/
      \ contains=texStatement,texInputCurlies,texInputFileOpt
syntax match texInputFile /\\subfile\s*\%(\[.\{-}\]\)\=\s*{.\{-}}/
      \ contains=texStatement,texInputCurlies,texInputFileOpt

" Allow subequations (fixes #1019)
" - This should be temporary, as it seems subequations is erroneously part of
"   texBadMath from Charles Campbell's syntax plugin.
syntax match texBeginEnd
      \ "\(\\begin\>\|\\end\>\)\ze{subequations}"
      \ nextgroup=texBeginEndName

" I don't quite see why we can't match Math zones in the MatchNMGroup
if !exists('g:tex_no_math')
  syntax cluster texMatchNMGroup add=@texMathZones
endif

" {{{1 Italic font, bold font and conceals

if get(g:, 'tex_fast', 'b') =~# 'b'
  let s:conceal = (has('conceal') && get(g:, 'tex_conceal', 'b') =~# 'b')
        \ ? 'concealends' : ''

  for [s:style, s:group, s:commands] in [
        \ ['texItalStyle', 'texItalGroup', ['emph', 'textit']],
        \ ['texBoldStyle', 'texBoldGroup', ['textbf']],
        \]
    for s:cmd in s:commands
      execute 'syntax region' s:style 'matchgroup=texTypeStyle'
            \ 'start="\\' . s:cmd . '\s*{" end="}"'
            \ 'contains=@Spell,@' . s:group
            \ s:conceal
    endfor
    execute 'syntax cluster texMatchGroup add=' . s:style
  endfor
endif

" }}}1
" {{{1 Add syntax highlighting of tabular specifications

if exists('b:vimtex.packages.tabularx') || exists('b:vimtex.packages.array')
  syntax cluster texDocGroup add=texTabular
  syntax match texTabular '\\begin{tabular}\_[^{]\{-}\ze{'
        \ contains=texBeginEnd
        \ nextgroup=texTabularArg
        \ contained
  syntax region texTabularArg matchgroup=Delimiter
        \ start='{' end='}'
        \ contained

  syntax match texTabularCol /[lcr]/
        \ containedin=texTabularArg
        \ contained
  syntax match texTabularCol /[pmb]/
        \ containedin=texTabularArg
        \ nextgroup=texTabularLength
        \ contained
  syntax match texTabularCol /\*/
        \ containedin=texTabularArg
        \ nextgroup=texTabularMulti
        \ contained
  syntax region texTabularMulti matchgroup=Delimiter
        \ start='{' end='}'
        \ containedin=texTabularArg
        \ nextgroup=texTabularArg
        \ contained

  syntax match texTabularAtSep /@/
        \ containedin=texTabularArg
        \ nextgroup=texTabularLength
        \ contained
  syntax match texTabularVertline /||\?/
        \ containedin=texTabularArg
        \ contained
  syntax match texTabularPostPre /[<>]/
        \ containedin=texTabularArg
        \ nextgroup=texTabularPostPreArg
        \ contained

  syntax region texTabularPostPreArg matchgroup=Delimiter
        \ start='{' end='}'
        \ containedin=texTabularArg
        \ contains=texLength,texStatement,texMathDelimSingle
        \ contained

  syntax region texTabularLength matchgroup=Delimiter
        \ start='{' end='}'
        \ containedin=texTabularArg
        \ contains=texLength,texStatement
        \ contained

  syntax match texMathDelimSingle /\$\$\?/
        \ containedin=texTabularPostPreArg
        \ contained

  highlight def link texTabularCol        Directory
  highlight def link texTabularAtSep      Type
  highlight def link texTabularVertline   Type
  highlight def link texTabularPostPre    Type
  highlight def link texMathDelimSingle   Delimiter
endif

" }}}1
" {{{1 Add syntax highlighting for \url, \href, \hyperref

syntax match texStatement '\\url\ze[^\ta-zA-Z]' nextgroup=texUrlVerb
syntax region texUrlVerb matchgroup=Delimiter
      \ start='\z([^\ta-zA-Z]\)' end='\z1' contained

syntax match texStatement '\\url\ze\s*{' nextgroup=texUrl
syntax region texUrl     matchgroup=Delimiter start='{' end='}' contained

syntax match texStatement '\\href' nextgroup=texHref
syntax region texHref matchgroup=Delimiter start='{' end='}' contained
      \ nextgroup=texMatcher

syntax match texStatement '\\hyperref' nextgroup=texHyperref
syntax region texHyperref matchgroup=Delimiter start='\[' end='\]' contained

highlight link texUrl          Function
highlight link texUrlVerb      texUrl
highlight link texHref         texUrl
highlight link texHyperref     texRefZone

" }}}1
" {{{1 Add support for biblatex and csquotes packages (cite commands)

if get(g:, 'tex_fast', 'r') =~# 'r'

  for s:pattern in [
        \ 'bibentry',
        \ 'cite[pt]?\*?',
        \ 'citeal[tp]\*?',
        \ 'cite(num|text|url)',
        \ '[Cc]ite%(title|author|year(par)?|date)\*?',
        \ '[Pp]arencite\*?',
        \ 'foot%(full)?cite%(text)?',
        \ 'fullcite',
        \ '[Tt]extcite',
        \ '[Ss]martcite',
        \ 'supercite',
        \ '[Aa]utocite\*?',
        \ '[Ppf]?[Nn]otecite',
        \ '%(text|block)cquote\*?',
        \]
    execute 'syntax match texStatement'
          \ '/\v\\' . s:pattern . '\ze\s*%(\[|\{)/'
          \ 'nextgroup=texRefOption,texCite'
  endfor

  for s:pattern in [
        \ '[Cc]ites',
        \ '[Pp]arencites',
        \ 'footcite%(s|texts)',
        \ '[Tt]extcites',
        \ '[Ss]martcites',
        \ 'supercites',
        \ '[Aa]utocites',
        \ '[pPfFsStTaA]?[Vv]olcites?',
        \ 'cite%(field|list|name)',
        \]
    execute 'syntax match texStatement'
          \ '/\v\\' . s:pattern . '\ze\s*%(\[|\{)/'
          \ 'nextgroup=texRefOptions,texCites'
  endfor

  for s:pattern in [
        \ '%(foreign|hyphen)textcquote\*?',
        \ '%(foreign|hyphen)blockcquote',
        \ 'hybridblockcquote',
        \]
    execute 'syntax match texStatement'
          \ '/\v\\' . s:pattern . '\ze\s*%(\[|\{)/'
          \ 'nextgroup=texQuoteLang'
  endfor

  syntax region texRefOptions contained matchgroup=Delimiter
        \ start='\[' end=']'
        \ contains=@texRefGroup,texRefZone
        \ nextgroup=texRefOptions,texCites

  syntax region texCites contained matchgroup=Delimiter
        \ start='{' end='}'
        \ contains=@texRefGroup,texRefZone,texCites
        \ nextgroup=texRefOptions,texCites

  syntax region texQuoteLang contained matchgroup=Delimiter
        \ start='{' end='}'
        \ transparent
        \ contains=@texMatchGroup
        \ nextgroup=texRefOption,texCite

  highlight def link texRefOptions texRefOption
  highlight def link texCites texCite
endif

" }}}1
" {{{1 Add support for array package

"
" The following code changes inline math so as to support the column
" specifiers [0], e.g.
"
"   \begin{tabular}{*{3}{>{$}c<{$}}}
"
" [0]: https://en.wikibooks.org/wiki/LaTeX/Tables#Column_specification_using_.3E.7B.5Ccmd.7D_and_.3C.7B.5Ccmd.7D
"

if exists('b:vimtex.packages.array') && get(g:, 'tex_fast', 'M') =~# 'M'
  syntax clear texMathZoneX
  if has('conceal') && &enc ==# 'utf-8' && get(g:, 'tex_conceal', 'd') =~# 'd'
    syntax region texMathZoneX matchgroup=Delimiter start="\([<>]{\)\@<!\$" skip="\%(\\\\\)*\\\$" matchgroup=Delimiter end="\$" end="%stopzone\>" concealends contains=@texMathZoneGroup
  else
    syntax region texMathZoneX matchgroup=Delimiter start="\([<>]{\)\@<!\$" skip="\%(\\\\\)*\\\$" matchgroup=Delimiter end="\$" end="%stopzone\>" contains=@texMathZoneGroup
  endif
endif

" }}}1
" {{{1 Add support for cleveref package
if get(g:, 'tex_fast', 'r') =~# 'r'
  syntax match texStatement '\\\(\(label\)\?c\(page\)\?\|C\|auto\)ref\>'
        \ nextgroup=texCRefZone

  " \crefrange, \cpagerefrange (these commands expect two arguments)
  syntax match texStatement '\\c\(page\)\?refrange\>'
        \ nextgroup=texCRefZoneRange skipwhite skipnl

  " \label[xxx]{asd}
  syntax match texStatement '\\label\[.\{-}\]'
        \ nextgroup=texCRefZone skipwhite skipnl
        \ contains=texCRefLabelOpts

  syntax region texCRefZone contained matchgroup=Delimiter
        \ start="{" end="}"
        \ contains=@texRefGroup,texRefZone
  syntax region texCRefZoneRange contained matchgroup=Delimiter
        \ start="{" end="}"
        \ contains=@texRefGroup,texRefZone
        \ nextgroup=texCRefZone skipwhite skipnl
  syntax region texCRefLabelOpts contained matchgroup=Delimiter
        \ start='\[' end=']'
        \ contains=@texRefGroup,texRefZone

  highlight link texCRefZone      texRefZone
  highlight link texCRefZoneRange texRefZone
  highlight link texCRefLabelOpts texCmdArgs
endif

" }}}1
" {{{1 Add support for varioref package
if get(g:, 'tex_fast', 'r') =~# 'r'
  syntax match texStatement '\\Vref\>' nextgroup=texVarioRefZone

  syntax region texVarioRefZone contained matchgroup=Delimiter
        \ start="{" end="}"
        \ contains=@texRefGroup,texRefZone

  highlight link texVarioRefZone texRefZone
endif

" }}}1
" {{{1 Add support for listings package
syntax region texZone
      \ start="\\begin{lstlisting}"rs=s
      \ end="\\end{lstlisting}\|%stopzone\>"re=e
      \ keepend
      \ contains=texBeginEnd
syntax match texInputFile
      \ "\\lstinputlisting\s*\(\[.*\]\)\={.\{-}}"
      \ contains=texStatement,texInputCurlies,texInputFileOpt
syntax match texZone "\\lstinline\s*\(\[.*\]\)\={.\{-}}"

" }}}1
" {{{1 Add support for moreverb package

if exists('g:tex_verbspell')
  syntax region texZone start="\\begin{verbatimtab}"   end="\\end{verbatimtab}\|%stopzone\>"   contains=@Spell
  syntax region texZone start="\\begin{verbatimwrite}" end="\\end{verbatimwrite}\|%stopzone\>" contains=@Spell
  syntax region texZone start="\\begin{boxedverbatim}" end="\\end{boxedverbatim}\|%stopzone\>" contains=@Spell
else
  syntax region texZone start="\\begin{verbatimtab}"   end="\\end{verbatimtab}\|%stopzone\>"
  syntax region texZone start="\\begin{verbatimwrite}" end="\\end{verbatimwrite}\|%stopzone\>"
  syntax region texZone start="\\begin{boxedverbatim}" end="\\end{boxedverbatim}\|%stopzone\>"
endif

" }}}1
" {{{1 Add support for beamer package
syntax match texBeamerDelimiter '<\|>' contained
syntax match texBeamerOpt '<[^>]*>' contained contains=texBeamerDelimiter

syntax match texStatementBeamer '\\only\(<[^>]*>\)\?' contains=texBeamerOpt
syntax match texStatementBeamer '\\item<[^>]*>' contains=texBeamerOpt

syntax match texInputFile
      \ '\\includegraphics<[^>]*>\(\[.\{-}\]\)\=\s*{.\{-}}'
      \ contains=texStatement,texBeamerOpt,texInputCurlies,texInputFileOpt

syntax cluster texDocGroup add=texStatementBeamer

highlight link texStatementBeamer texStatement
highlight link texBeamerOpt Identifier
highlight link texBeamerDelimiter Delimiter

" }}}1
" {{{1 Add support for amsmath package

" This is based on Charles E. Campbell's amsmath.vba file dated 2017-10-12

call TexNewMathZone('Z', 'align', 1)
call TexNewMathZone('Y', 'alignat', 1)
call TexNewMathZone('X', 'equation', 1)
call TexNewMathZone('W', 'flalign', 1)
call TexNewMathZone('V', 'gather', 1)
call TexNewMathZone('U', 'multline', 1)
call TexNewMathZone('T', 'xalignat', 1)
call TexNewMathZone('S', 'xxalignat', 0)

execute 'syntax match texBadMath ''\\end\s*{\s*\(' . join([
      \ 'align',
      \ 'alignat',
      \ 'equation',
      \ 'flalign',
      \ 'gather',
      \ 'multline',
      \ 'xalignat',
      \ 'xxalignat'], '\|') . '\)\*\=\s*}'''

" Amsmath [lr][vV]ert  (Holger Mitschke)
for s:texmath in [
      \ ['\\lvert', '|'] ,
      \ ['\\rvert', '|'] ,
      \ ['\\lVert', '‖'] ,
      \ ['\\rVert', '‖'] ,
      \ ]
  execute "syntax match texMathDelim '\\\\[bB]igg\\=[lr]\\="
        \ . s:texmath[0] . "' contained conceal cchar=" . s:texmath[1]
endfor

" }}}1
" {{{1 Nested syntax highlighting for dot
unlet b:current_syntax
syntax include @DOT syntax/dot.vim
syntax cluster texDocGroup add=texZoneDot
syntax region texZoneDot
      \ start="\\begin{dot2tex}"rs=s
      \ end="\\end{dot2tex}"re=e
      \ keepend
      \ transparent
      \ contains=texBeginEnd,@DOT
let b:current_syntax = 'tex'

" }}}1
" {{{1 Nested syntax highlighting for lualatex
unlet b:current_syntax
syntax include @LUA syntax/lua.vim
syntax cluster texDocGroup add=texZoneLua
syntax region texZoneLua
      \ start='\\begin{luacode\*\?}'rs=s
      \ end='\\end{luacode\*\?}'re=e
      \ keepend
      \ transparent
      \ contains=texBeginEnd,@LUA
syntax match texStatement '\\\(directlua\|luadirect\)' nextgroup=texZoneLuaArg
syntax region texZoneLuaArg matchgroup=Delimiter
      \ start='{'
      \ end='}'
      \ contained
      \ contains=@LUA
let b:current_syntax = 'tex'

" }}}1
" {{{1 Nested syntax highlighting for gnuplottex
unlet b:current_syntax
syntax include @GNUPLOT syntax/gnuplot.vim
syntax cluster texDocGroup add=texZoneGnuplot
syntax region texZoneGnuplot
      \ start='\\begin{gnuplot}\(\_s*\[\_[\]]\{-}\]\)\?'rs=s
      \ end='\\end{gnuplot}'re=e
      \ keepend
      \ transparent
      \ contains=texBeginEnd,texBeginEndModifier,@GNUPLOT
let b:current_syntax = 'tex'

" }}}1
" {{{1 Nested syntax highlighting for asymptote

syntax cluster texDocGroup add=texZoneAsymptote

let s:asypath = globpath(&runtimepath, 'syntax/asy.vim')
if !empty(s:asypath)
  unlet b:current_syntax
  syntax include @ASYMPTOTE syntax/asy.vim
  syntax region texZoneAsymptote
        \ start='\\begin{asy\z(def\)\?}'rs=s
        \ end='\\end{asy\z1}'re=e
        \ keepend
        \ transparent
        \ contains=texBeginEnd,@ASYMPTOTE
  let b:current_syntax = 'tex'
else
  syntax region texZoneAsymptote
        \ start='\\begin{asy\z(def\)\?}'rs=s
        \ end='\\end{asy\z1}'re=e
        \ keepend
        \ contains=texBeginEnd
  highlight def link texZoneAsymptote texZone
endif

" }}}1
" {{{1 Nested syntax highlighting for minted

" First set all minted environments to listings
syntax cluster texFoldGroup add=texZoneMinted
syntax region texZoneMinted
      \ start="\\begin{minted}\_[^}]\{-}{\w\+}"rs=s
      \ end="\\end{minted}"re=e
      \ keepend
      \ contains=texMinted

" Highlight "unknown" statements
syntax region texMintArgUnknown matchgroup=Delimiter
      \ start='{'
      \ end='}'
      \ contained
      \ nextgroup=texMintZoneUnknown
syntax region texMintZoneUnknown matchgroup=Delimiter
      \ start='\z([|+/]\)'
      \ end='\z1'
      \ contained
syntax region texMintZoneUnknown matchgroup=Delimiter
      \ start='{'
      \ end='}'
      \ contained

" Next add nested syntax support for desired languages
for s:entry in get(g:, 'vimtex_syntax_minted', [])
  let s:lang = s:entry.lang
  let s:syntax = get(s:entry, 'syntax', s:lang)

  let s:cap_name = toupper(s:lang[0]) . s:lang[1:]
  let s:group_name = 'texZoneMinted' . s:cap_name
  execute 'syntax cluster texFoldGroup add=' . s:group_name

  unlet b:current_syntax
  execute 'syntax include @' . toupper(s:lang) 'syntax/' . s:syntax . '.vim'

  if has_key(s:entry, 'ignore')
    execute 'syntax cluster' toupper(s:lang)
          \ 'remove=' . join(s:entry.ignore, ',')
  endif

  " Add statement variants
  " - \mint[]{lang}|...|
  " - \mint[]{lang}{...}
  " - \mintinline[]{lang}|...|
  " - \mintinline[]{lang}{...}
  execute 'syntax match texMintArg' . s:cap_name  '''{' . s:lang . '}'''
        \ 'contained'
        \ 'nextgroup=texMintZone' . s:cap_name
  execute 'syntax region texMintZone' . s:cap_name
        \ 'matchgroup=Delimiter'
        \ 'start=''\z([|+/]\)'''
        \ 'end=''\z1'''
        \ 'contained'
        \ 'contains=@' . toupper(s:lang)
  execute 'syntax region texMintZone' . s:cap_name
        \ 'matchgroup=Delimiter'
        \ 'start=''{'''
        \ 'end=''}'''
        \ 'contained'
        \ 'contains=@' . toupper(s:lang)

  " Add main minted environment
  execute 'syntax region' s:group_name
        \ 'start="\\begin{minted}\_[^}]\{-}{' . s:lang . '}"rs=s'
        \ 'end="\\end{minted}"re=e'
        \ 'keepend'
        \ 'transparent'
        \ 'contains=texMinted,@' . toupper(s:lang)

  " Support for custom environment names
  for s:env in get(s:entry, 'environments', [])
    execute 'syntax region' s:group_name
          \ 'start="\\begin{' . s:env . '}"rs=s'
          \ 'end="\\end{' . s:env . '}"re=e'
          \ 'keepend'
          \ 'transparent'
          \ 'contains=texBeginEnd,@' . toupper(s:lang)

    " Match starred environments with options
    execute 'syntax region' s:group_name
          \ 'start="\\begin{' . s:env . '\*}\s*{\_.\{-}}"rs=s'
          \ 'end="\\end{' . s:env . '\*}"re=e'
          \ 'keepend'
          \ 'transparent'
          \ 'contains=texMintedStarred,texBeginEnd,@' . toupper(s:lang)
    execute 'syntax match texMintedStarred'
          \ '"\\begin{' . s:env . '\*}\s*{\_.\{-}}"'
          \ 'contains=texBeginEnd,texDelimiter'
  endfor

  " Support for custom commands
  for s:cmd in sort(get(s:entry, 'commands', []))
    execute 'syntax match texStatement'
          \ '''\\' . s:cmd . ''''
          \ 'nextgroup=texMintZone' . s:cap_name
  endfor
endfor
let b:current_syntax = 'tex'

" Main matcher for the minted statements/commands (must come last to allow
" nextgroup patterns)
syntax match texStatement '\\mint\(inline\)\?' nextgroup=texMintOptArg,texMintArg.*
syntax region texMintOptArg matchgroup=Delimiter
      \ start='\['
      \ end='\]'
      \ contained
      \ nextgroup=texMintArg.*

syntax match texMinted '\\begin{minted}\_[^}]\{-}{\w\+}'
      \ contains=texBeginEnd,texMintedName
syntax match texMinted '\\end{minted}'
      \ contains=texBeginEnd
syntax match texMintedName '{\w\+}' contained

highlight link texMintZoneUnknown texZone
highlight link texMintedName texBeginEndName

" }}}1
" {{{1 Nested syntax highlighting for pythontex

if exists('b:vimtex.packages.pythontex')
  unlet b:current_syntax
  syntax include @PYTHON syntax/python.vim
  let b:current_syntax = 'tex'

  syntax cluster PYTHON remove=pythonEscape
  syntax cluster PYTHON remove=pythonBEscape
  syntax cluster PYTHON remove=pythonBytesEscape

  syntax match texStatement /\\py[bsc]\?/ contained nextgroup=texPythontexArg
  syntax region texPythontexArg matchgroup=Delimiter
        \ start='{' end='}'
        \ contained contains=@PYTHON
  syntax region texPythontexArg matchgroup=Delimiter
        \ start='\z([#@]\)' end='\z1'
        \ contained contains=@PYTHON

  syntax cluster texDocGroup add=texZonePythontex
  syntax region texZonePythontex
        \ start='\\begin{pyblock}'rs=s
        \ end='\\end{gnuplot}'re=e
        \ keepend
        \ transparent
        \ contains=texBeginEnd,texBeginEndModifier,@PYTHON
  syntax region texZonePythontex
        \ start='\\begin{pycode}'rs=s
        \ end='\\end{pycode}'re=e
        \ keepend
        \ transparent
        \ contains=texBeginEnd,texBeginEndModifier,@PYTHON
endif

" }}}1
