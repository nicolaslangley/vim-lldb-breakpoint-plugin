" See :help signs for more details
execute "sign define BreakpointSet text=b"
let g:lldb_dir="/Users/nico8506/.lldb/"
let g:lldb_breakpoint_count=1
let g:lldb_executable="runtimecore_testd"
let g:lldb_breakpoint_group=""

function SetLLDBDir(lldb_dir)
  let g:lldb_dir=a:lldb_dir
endfunction

function SetLLDBExecutable(executable)
  let g:lldb_executable = a:executable
endfunction

function SetLLDBBreakpointGroup(breakpoint_group)
  let g:lldb_breakpoint_group = a:breakpoint_group
endfunction

function SetLLDBBreakpoint()
  let l:output_file_name=g:lldb_dir . ".breakpoints_" . g:lldb_executable . "_" . g:lldb_breakpoint_group
  let l:file_name=expand('%:t')
  let l:file_line=line(".")
  let l:breakpoint_loc_list=["b " . file_name . ":" . file_line]
  call writefile(breakpoint_loc_list, output_file_name, "a")
  execute printf('sign place %d line=%d name=%s file=%s',
                  \ g:lldb_breakpoint_count,
                  \ file_line,
                  \ "BreakpointSet",
                  \ expand('%:p'))
  echo "Breakpoint set"
endfunction
