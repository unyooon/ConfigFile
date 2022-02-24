if g:dein#_cache_version !=# 100 || g:dein#_init_runtimepath !=# '/home/nyal/.config/nvim,/etc/xdg/nvim,/home/nyal/.local/share/nvim/site,/usr/local/share/nvim/site,/usr/share/nvim/site,/var/lib/snapd/desktop/nvim/site,/usr/share/nvim/runtime,/var/lib/snapd/desktop/nvim/site/after,/usr/share/nvim/site/after,/usr/local/share/nvim/site/after,/home/nyal/.local/share/nvim/site/after,/etc/xdg/nvim/after,/home/nyal/.config/nvim/after,/usr/share/vim/vimfiles,/home/nyal/.config/nvim/dein/repos/github.com/Shougo/dein.vim' | throw 'Cache loading error' | endif
let [plugins, ftplugin] = dein#load_cache_raw(['/home/nyal/.config/nvim/init.vim', '/home/nyal/.config/nvim/dein/toml/dein.toml', '/home/nyal/.config/nvim/dein/toml/dein_lazy.toml'])
if empty(plugins) | throw 'Cache loading error' | endif
let g:dein#_plugins = plugins
let g:dein#_ftplugin = ftplugin
let g:dein#_base_path = '/home/nyal/.config/nvim/dein'
let g:dein#_runtime_path = '/home/nyal/.config/nvim/dein/.cache/init.vim/.dein'
let g:dein#_cache_path = '/home/nyal/.config/nvim/dein/.cache/init.vim'
let &runtimepath = '/home/nyal/.config/nvim,/etc/xdg/nvim,/home/nyal/.local/share/nvim/site,/usr/local/share/nvim/site,/usr/share/nvim/site,/var/lib/snapd/desktop/nvim/site,/home/nyal/.config/nvim/dein/repos/github.com/Shougo/dein.vim,/home/nyal/.config/nvim/dein/.cache/init.vim/.dein,/usr/share/nvim/runtime,/home/nyal/.config/nvim/dein/.cache/init.vim/.dein/after,/var/lib/snapd/desktop/nvim/site/after,/usr/share/nvim/site/after,/usr/local/share/nvim/site/after,/home/nyal/.local/share/nvim/site/after,/etc/xdg/nvim/after,/home/nyal/.config/nvim/after,/usr/share/vim/vimfiles'
filetype off
autocmd dein-events InsertEnter * call dein#autoload#_on_event("InsertEnter", ['deoplete.nvim', 'neosnippet', 'vim-commentary'])
