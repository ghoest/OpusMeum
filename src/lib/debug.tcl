# vim: filetype=tcl shiftwidth=4 smarttab expandtab
####################################################################################################
# NAME       : debug.tcl
#
# SYNTAX     : debug.tcl
#
# DESCRIPTION: debugging procedures.
#
# PROCEDURES : _print_taginfo
#              _taginfo
#              _procs
#              _vars
#              debug_init
#
# VARIABLES  :
#              ::__tkconloaded
################################################################################

# Do initialization type stuff at the end of gui building...
lappend ::_appinit debug_init

################################################################################
#   Procedure: debug_init
#
# Description: perform any work that should be done immeadiately before a template
#              is loaded.
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc debug_init {} {
    # Create the debugging menu item
    menu .mb.mdebug -tearoff 0
    .mb add cascade -menu .mb.mdebug -label "Debug"
    # Add tkcon as as debugging console
    .mb.mdebug add command -label "Console" -command {
        if {![info exists ::__tkconloaded]} {
            source [file join $basedir "lib" "tkcon.tcl"]
            package require tkcon
            # http://wiki.tcl.tk/17616 -- TkCon as an application console
            #------------------------------------------------------
            #  The console doesn't exist yet.  If we create it
            #  with show/hide, then it flashes on the screen.
            #  So we cheat, and call tkcon internals to create
            #  the console and customize it to our application.
            #------------------------------------------------------
            set tkcon::PRIV(showOnStartup) 0
            set tkcon::PRIV(root) .console
            set tkcon::PRIV(protocol) {tkcon hide}
            set tkcon::OPT(exec) ""
            tkcon::Init
            tkcon title "[::omApp name] Console"
            set ::__tkconloaded TRUE
        }
        tkcon show
    }
}


################################################################################
#   Procedure: _taginfo
#
# Description: populate 'infoArray' with detail from the various tagged blocks
#
# Parameters
# ==========
# infoArray         I/O  Array to populate (unset before use)
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc _taginfo {txtwidget infoArray} {
    upvar 1 $infoArray iArray
    array unset iArray
    foreach tagname [$txtwidget tag names] {
        if {[string first "_" $tagname] != -1} {
            set tagtype [lindex [split $tagname _] 0]
            set tagrange [$txtwidget tag ranges $tagname]
            if {[llength $tagrange] == 2} {
                lappend iArray($tagtype) [string trim [$txtwidget get {*}$tagrange]]
            }
        }
    }
}


################################################################################
#   Procedure: _print_taginfo
#
# Description: Print tag content information summary
#
# Parameters
# ==========
# None.
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc _print_taginfo {txtwidget} {
    unset -nocomplain infoArray
    _taginfo $txtwidget infoArray
    foreach type [array names infoArray] {
        puts [format "%-10s total: %4s  unique: %4s" $type \
                [llength [lsort $infoArray($type)]] \
                [llength [lsort -unique $infoArray($type)]]]
    }
}


proc _procs {} {
    set ignore [list \
        abs acos alias asin assign_fields atan atan2 auto_execok auto_load_index auto_import \
        auto_load auto_mkindex auto_mkindex_old auto_reset auto_qualify \
        ceil cexpand clear clock convertclock convert_lib copy_dll_from_tm copyfile cos cosh \
        dir dirs double dump \
        echo edit edprocs exit exp \
        fabs floor fmod fmtclock for_array_keys for_file for_recursive_glob frename \
        getclock \
        history \
        idebug int intersect intersect3 \
        load_twapi_dll log log10 lremove lrmdups \
        mainloop mkdir \
        observe observe_var \
        pkg_mkIndex popd pow profrep pushd \
        read_file recursive_glob round rmdir \
        saveprocs server_cntl server_connect server_info server_open server_send showproc sin sinh \
        sqrt \
        tan tanh tcl_endOfWord tcl_findLibrary tcl_startOfNextWord tcl_startOfPreviousWord \
        tcl_unknown tcl_wordBreakAfter tcl_wordBreakBefore tclLog tclPkgSetup tclPkgUnknown \
        tkcon_gets tkcon_puts tk_menuSetFocus tk_popup tk_textCopy tk_textCut tk_textPaste \
        unalias union unknown unlink \
        what which write_file]

    set ignore [lsort -unique $ignore]
    # At a minumum, this procedure will be listed.
    foreach procedure [uplevel #0 info procs] {
        if {[lsearch -exact $ignore $procedure] == -1} {
            lappend rtn $procedure
        }
    }
    return [lsort $rtn]
}

proc _vars {} {
    set ignore [list TCLXENV _ \
        argc argv argv0 auto_index auto_oldpath auto_path env errorCode errorInfo \
        tcl_interactive tcl_libPath tcl_library tcl_nonwordchars tcl_patchLevel tcl_pkgPath \
        tcl_platform tcl_rcFileName tcl_version tcl_wordchars tclx_library tk_library \
        tk_patchLevel tk_strictMotif tk_version unknown_handler_order unknown_handlers]

    set ignore [lsort -unique $ignore]
    # At a minumum, this procedure will be listed.
    foreach var [uplevel #0 info vars] {
        if {[lsearch -exact $ignore $var] == -1} {
            lappend rtn $var
        }
    }
    return [lsort $rtn]
}
