" Define sign for breakpoint identifier
" See :help signs for more details
execute "sign define BreakpointSet text=b"
let g:sign_bp_dict={} " Define empty global dictionary for sign ID and breakpoint strings

" Global settings - sensible defaults can be set here
let g:lldb_dir="/Users/nico8506/.lldb/"
let g:lldb_executable="runtimecore_testd"
let g:lldb_breakpoint_group="default"
let g:globals_save_path="/Users/nico8506/.config/nvim/plugged/vim-lldb-breakpoints/vim-lldb-breakpoint-globals.vim"

" Global script variables
let g:lldb_breakpoint_count=1 " Used to set sign ID

" Save global settings to file
function SaveGlobalSettings()
  execute "redir! > " . g:globals_save_path
  echo g:lldb_dir
  echo g:lldb_executable
  echo g:lldb_breakpoint_group
  echo g:globals_save_path
  execute "redir END"
endfunction
autocmd VimLeave * :exec SaveGlobalSettings()

" Load global settings from saved file
function LoadGlobalSettings()
  if !filereadable(g:globals_save_path)
    call system("touch " . g:globals_save_path)
  endif
  let l:globals_list=readfile(g:globals_save_path)
  echo globals_list
  let g:lldb_dir=globals_list[1]
  let g:lldb_executable=globals_list[2]
  let g:lldb_breakpoint_group=globals_list[3]
  let g:globals_save_path=globals_list[4]
endfunction
autocmd VimEnter * :exec LoadGlobalSettings()

" Remove breakpoint signs for existing LLDB breakpoints
function! RemoveBreakpointSigns()
  for id in values(g:sign_bp_dict)
    execute printf("sign unplace %d", id)
  endfor
  let g:sign_bp_dict={}
endfunction
" Autocommand to check for and remove breakpoint signs when closing buffer
autocmd BufWinLeave * :exec RemoveBreakpointSigns()

" Add breakpoint signs for existing LLDB breakpoints
function! AddBreakpointSigns()
  let l:output_file_name=g:lldb_dir . ".breakpoints_" . g:lldb_executable . "_" . g:lldb_breakpoint_group
  if !filereadable(output_file_name)
    call system("touch " . output_file_name)
  endif
  let l:breakpoint_list=readfile(output_file_name)
  for breakpoint in breakpoint_list " Identify if breakpoint is currently set for this file
    let l:breakpoint_split=split(split(breakpoint)[1], ":")
    let l:file_name=breakpoint_split[0]
    if file_name == expand("%:t")
      let l:file_line=breakpoint_split[1]
      execute printf("sign place %d line=%d name=%s file=%s",
                      \ g:lldb_breakpoint_count,
                      \ file_line,
                      \ "BreakpointSet",
                      \ expand("%:p")) 
      let g:sign_bp_dict[breakpoint]=g:lldb_breakpoint_count " Key is breakpoints string and value is sign ID
      let g:lldb_breakpoint_count += 1
    endif
  endfor
endfunction
" Autocommand to check for and add breakpoint signs on buffer open
autocmd BufWinEnter * :exec AddBreakpointSigns()

" Set the directory for your .lldb folder directory
function! SetLLDBDir(lldb_dir)
  let g:lldb_dir=a:lldb_dir
  for id in values(g:sign_bp_dict)
    execute printf("sign unplace %d", id)
  endfor
  let g:sign_bp_dict={}
endfunction

" Set the current executable to set LLDB breakpoints for
function! SetLLDBExecutable(executable)
  let g:lldb_executable = a:executable
  for id in values(g:sign_bp_dict)
    execute printf("sign unplace %d", id)
  endfor
  let g:sign_bp_dict={}
endfunction

" Set the group identifier to be used for the breakpoints
function! SetLLDBBreakpointGroup(breakpoint_group)
  let g:lldb_breakpoint_group = a:breakpoint_group
  for id in values(g:sign_bp_dict)
    execute printf("sign unplace %d", id)
  endfor
  let g:sign_bp_dict={}
endfunction

" Set LLDB breakpoint - uses previously set executable and breakpoint group
function! SetLLDBBreakpoint()
  let l:output_file_name=g:lldb_dir . ".breakpoints_" . g:lldb_executable . "_" . g:lldb_breakpoint_group
  let l:file_name=expand("%:t")
  let l:file_line=line(".")
  let l:breakpoint_loc_list=["b " . file_name . ":" . file_line]
  call writefile(breakpoint_loc_list, output_file_name, "a")
  execute printf("sign place %d line=%d name=%s file=%s",
                  \ g:lldb_breakpoint_count,
                  \ file_line,
                  \ "BreakpointSet",
                  \ expand("%:p"))
  let g:sign_bp_dict[breakpoint_loc_list[0]]=g:lldb_breakpoint_count " Key is breakpoints string and value is sign ID
  let g:lldb_breakpoint_count += 1
  echo "Breakpoint set: " . breakpoint_loc_list[0]
endfunction

" Remove LLDB breakpoint - uses previously set executable and breakpoint group
function RemoveLLDBBreakpoint()
  let l:output_file_name=g:lldb_dir . ".breakpoints_" . g:lldb_executable . "_" . g:lldb_breakpoint_group
  let l:file_name=expand("%:t")
  let l:file_line=line(".")
  let l:breakpoint_name="b " . file_name . ":" . file_line
  if !filereadable(output_file_name)
    call system("touch " . output_file_name)
  endif
  let l:breakpoint_list=readfile(output_file_name)
  let l:list_counter = 0
  let l:breakpoint_found = 0
  for breakpoint in breakpoint_list " Identify if breakpoint is currently set for this file
    if breakpoint == breakpoint_name
      let l:breakpoint_found = 1
      break
    endif
    let l:list_counter += 1
  endfor
  if breakpoint_found == 1
    call remove(breakpoint_list, list_counter)
  endif
  call writefile(breakpoint_list, output_file_name) " Overwrite the file with updated breakpoint list
  let l:sign_id = get(g:sign_bp_dict, breakpoint_name)
  if sign_id != 0 " Remove sign for this breakpoint if it exists
    execute printf("sign unplace %d", sign_id)
    call remove(g:sign_bp_dict, breakpoint_name)
    echo "Breakpoint removed: " . breakpoint_name
  endif
endfunction

" Plugin Mappings
nnoremap <leader>ba :call SetLLDBBreakpoint()<cr>
nnoremap <leader>bd :call RemoveLLDBBreakpoint()<cr>



