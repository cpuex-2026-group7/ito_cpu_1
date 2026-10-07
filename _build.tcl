# build.tcl - Vivado batch helper (no GUI)
#
# Put this file next to the .xpr and run in that directory:
#   vivado -mode batch -nojournal -notrace -source build.tcl -tclargs [mode] [clean]
#
# mode:
#   all      (default) build bitstream if needed, then program the board
#   build    build bitstream only
#   program  program the board with the existing bitstream
#   errors   show ERROR / CRITICAL WARNING of the last run (no build)
#   status   show run status and timing summary
# clean      force re-run of synthesis + implementation
#
# Exit code: 0 = success, 1 = failure (usable from shell scripts)

set script_dir [file dirname [file normalize [info script]]]

proc die {msg} {
    puts stderr "\n*** FAILED: $msg\n"
    exit 1
}

proc section {title} {
    puts "\n========== $title =========="
}

proc cpu_count {} {
    if {[info exists ::env(NUMBER_OF_PROCESSORS)]} {
        return $::env(NUMBER_OF_PROCESSORS)
    }
    if {![catch {exec nproc} n]} {
        return $n
    }
    return 4
}

# ---------------------------------------------------------------
# messages / reports
# ---------------------------------------------------------------

# Print ERROR and CRITICAL WARNING lines from every run's log.
# Returns the number of errors.
proc show_run_messages {} {
    set n_err 0
    set n_crit 0
    set n_warn 0
    foreach run [get_runs] {
        set log [file join [get_property DIRECTORY $run] runme.log]
        if {![file exists $log]} { continue }
        set fh [open $log r]
        set seen [dict create]
        set lines {}
        while {[gets $fh line] >= 0} {
            if {[regexp {^(ERROR|CRITICAL WARNING):} $line -> kind]} {
                if {[dict exists $seen $line]} { continue }
                dict set seen $line 1
                lappend lines $line
                if {$kind eq "ERROR"} { incr n_err } else { incr n_crit }
            } elseif {[string match "WARNING:*" $line]} {
                incr n_warn
            }
        }
        close $fh
        if {[llength $lines] > 0} {
            puts "\n--- $run : [get_property STATUS $run] ---"
            foreach l $lines { puts "  $l" }
        }
    }
    section "Messages"
    puts "$n_err error(s), $n_crit critical warning(s), $n_warn warning(s)"
    puts "full logs: <project>.runs/<run>/runme.log"
    return $n_err
}

proc show_timing {} {
    set impl [get_runs impl_1]
    if {[catch {get_property STATS.WNS $impl} wns] || $wns eq ""} {
        puts "Timing: no data (implementation not finished)"
        return
    }
    set whs [get_property STATS.WHS $impl]
    puts "Timing: WNS = $wns ns, WHS = $whs ns"
    if {[catch {expr {$wns < 0 || $whs < 0}} bad] == 0 && $bad} {
        puts "  !!! TIMING VIOLATED - design may misbehave on the board"
    }
}

proc show_status {} {
    section "Run status"
    foreach run [get_runs] {
        puts [format "  %-28s %-6s %s" $run \
                  [get_property PROGRESS $run] [get_property STATUS $run]]
    }
}

proc run_failed {run} {
    return [expr {[get_property PROGRESS $run] ne "100%" ||
                  [string match "*ERROR*" [get_property STATUS $run]]}]
}

proc bitfile_path {} {
    set top [get_property top [current_fileset]]
    return [file join [get_property DIRECTORY [get_runs impl_1]] "$top.bit"]
}

# ---------------------------------------------------------------
# build
# ---------------------------------------------------------------
proc build_bitstream {force} {
    section "Build"
    update_compile_order -fileset sources_1

    set locked [get_ips -quiet -filter {IS_LOCKED == 1}]
    if {[llength $locked] > 0} {
        die "locked IP: $locked\n    (Vivado version mismatch?)\
             Open GUI -> Reports -> Report IP Status -> Upgrade"
    }

    set synth [get_runs synth_1]
    set impl  [get_runs impl_1]
    set bit   [bitfile_path]

    set need_synth [expr {$force ||
                          [get_property NEEDS_REFRESH $synth] ||
                          [get_property PROGRESS $synth] ne "100%"}]
    set need_impl  [expr {$need_synth ||
                          [get_property NEEDS_REFRESH $impl] ||
                          [get_property PROGRESS $impl] ne "100%" ||
                          ![file exists $bit]}]

    if {!$need_impl} {
        puts "Up to date, skip build: $bit"
        return $bit
    }

    catch {reset_run $impl}
    if {$need_synth} { catch {reset_run $synth} }

    set jobs [cpu_count]
    puts "Launching synth/impl/write_bitstream (jobs = $jobs) ..."
    launch_runs $impl -to_step write_bitstream -jobs $jobs

    wait_on_run $synth
    if {[run_failed $synth]} {
        show_run_messages
        die "synthesis failed"
    }
    wait_on_run $impl
    if {[run_failed $impl] || ![file exists $bit]} {
        show_run_messages
        die "implementation / bitstream failed"
    }

    show_run_messages
    show_timing
    puts "Bitstream: $bit"
    return $bit
}

# ---------------------------------------------------------------
# program
# ---------------------------------------------------------------
proc program_device {bit} {
    section "Program"
    if {![file exists $bit]} {
        die "bitstream not found: $bit  (run with 'build' first)"
    }

    if {[catch {open_hw_manager}]} { open_hw }
    if {[catch {connect_hw_server -allow_non_jtag}]} { connect_hw_server }

    set targets [get_hw_targets -quiet]
    if {[llength $targets] == 0} {
        die "no board found - check USB cable / power switch / driver"
    }
    current_hw_target [lindex $targets 0]
    open_hw_target

    set dev [lindex [get_hw_devices -quiet xc7a*] 0]
    if {$dev eq ""} { set dev [lindex [get_hw_devices] 0] }
    current_hw_device $dev
    refresh_hw_device -update_hw_probes false $dev

    set ltx "[file rootname $bit].ltx"
    if {[file exists $ltx]} {
        set_property PROBES.FILE      $ltx $dev
        set_property FULL_PROBES.FILE $ltx $dev
    } else {
        set_property PROBES.FILE      {} $dev
        set_property FULL_PROBES.FILE {} $dev
    }
    set_property PROGRAM.FILE $bit $dev

    puts "Programming $dev with $bit ..."
    if {[catch {program_hw_devices $dev} err]} {
        die "program_hw_devices failed: $err"
    }

    close_hw_target
    disconnect_hw_server
    catch {close_hw_manager}
    puts "Done."
}

# ---------------------------------------------------------------
# main
# ---------------------------------------------------------------
set mode  "all"
set force 0
foreach a $argv {
    switch -- $a {
        all - build - program - errors - status { set mode $a }
        clean   { set force 1 }
        default { die "unknown argument: $a  (all|build|program|errors|status [clean])" }
    }
}

set xprs [glob -nocomplain -directory $script_dir *.xpr]
if {[llength $xprs] != 1} {
    die "expected exactly one .xpr in $script_dir (found [llength $xprs])"
}
open_project [lindex $xprs 0]

set rc 0
switch -- $mode {
    all     { program_device [build_bitstream $force] }
    build   { build_bitstream $force }
    program { program_device [bitfile_path] }
    errors  { set rc [expr {[show_run_messages] > 0}]; show_timing }
    status  { show_status; show_timing }
}

close_project
exit $rc
