# sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE

set current_monitor (aerospace list-monitors --focused | awk '{print $1}')
set pip_windows (aerospace list-windows --monitor "$current_monitor" | grep -E "(Picture-in-Picture|Picture in Picture)" | awk '{print $1}')

set current_workspace (aerospace list-workspaces --focused)

for n in $pip_windows
    echo "processing window $n"
    aerospace move-node-to-workspace --window-id "$n" "$current_workspace"
end
