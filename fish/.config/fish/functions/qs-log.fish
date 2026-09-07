function qs-log --description "Tail the running quickshell session's log"
    set -l runtime_dir $XDG_RUNTIME_DIR
    if test -z "$runtime_dir"
        set runtime_dir /run/user/(id -u)
    end

    set -l log (command ls -t $runtime_dir/quickshell/by-id/*/log.log 2>/dev/null | head -1)
    if test -z "$log"
        echo "qs-log: no running quickshell log found" >&2
        return 1
    end

    tail -f "$log"
end
