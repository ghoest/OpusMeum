####################################################################################################
#/---------------------------------------
#| Name    plink.tcl
#\---------------------------------------
#
# Description
#     Markup Tag {plink}.  Use plink to run small 'scripts' on the remote host.
#
# PROCEDURES : plink_bgjob
#              plink_edit
#              plink_mtag
#              plink_output
#              plink_preload
#              plink_reset
#              plink_run
#              plink_save
#
# VARIABLES  : ::_before_processing_template  -- used in OpusMeum.tcl
#              ::_known_markup                -- used in OpusMeum.tcl
#              ::appcfg                       -- From OpusMeum.tcl
#
####################################################################################################
lappend ::_known_markup {plink}

# Reset header related variables on template load
lappend ::_before_load_template plink_preload

# TODO jg: should we check if a session is configured before trying to use it?
#          the call is made in plink_run, but it probably makes sense to load
#          the info once... so either at the time this file is loaded or at
#          the loop for $::_appinit at the end of OpusMeum.tcl.
#
# ::config create ::putty -app "SimonTatham\\PuTTY" -readonly TRUE
# # Then when we check, do something like this...
# if {[::putty get [list Sessions $sessionName]] eq ""} {
#     error "The sessions is not defined"
# }
::appcfg set plink [file join "C:/" "Program Files" "PuTTY" "plink.exe"]

################################################################################
#   Procedure: plink_bgjob
#
# Description: Monitor for completion of job and when complete update the block
#              for output window (left-click) and reset(double right-click).
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc plink_bgjob {chandle txtwidget uniqtag} {
    if {![info exists ::output($uniqtag)]} {
        set ::output($uniqtag) ""
    }
    if {[eof $chandle]} {
        # The running command has completed... set back to blocking, otherwise errors won't
        # be caught on close...
        fconfigure $chandle -blocking TRUE
        # is this really necessary? is there going to be anything left at this point?
        #append ::output($uniqtag) [read $chandle]
        set result [catch {close $chandle} err]

        if {$result} {
            # Add what ever is available on stderr to the end of the output.
            append ::output($uniqtag) $err
            # A shade of red
            set color #F56E7E
        } else {
            # A shade of green
            set color #68F27B
        }
        if {[info exists ::_csrloc($txtwidget)] && \
                [lsearch -exact [$txtwidget tag names @$::_csrloc($txtwidget)] $uniqtag] != -1} {
            # The cursor is in the block, change to the hand cursor...
            $txtwidget configure -cursor hand2
        }
        $txtwidget configure -state normal
        $txtwidget tag bind $uniqtag <Enter> {%W configure -cursor hand2}
        $txtwidget tag bind $uniqtag <Button-1> \
            [list plink_output $txtwidget $uniqtag $::output($uniqtag)]
        $txtwidget tag bind $uniqtag <Double-Button-3> [list plink_reset $txtwidget $uniqtag]
        $txtwidget tag configure $uniqtag -background $color
        $txtwidget configure -state disabled
    } else {
        # Append what's available on standard out
        append ::output($uniqtag) [read $chandle]
    }
    return
}


################################################################################
#   Procedure: plink_edit
#
# Description: Dialog to edit a plink block
#
# Parameters
# ==========
# txtwidget         I   txt widget to interact with.
# tag               I   tag of plink block to edit.
#
# Return Value
# ============
# true/false
#
# Error Handling
# ==============
# None.
################################################################################
proc plink_edit {txtwidget tag} {

    set editrange [$txtwidget tag ranges $tag]
    set edittext [string trimright [$txtwidget get {*}$editrange]]

    if {![winfo exists .plinkedit]} {
        # The edit window doesn't exist, create it
        toplevel .plinkedit
        text .plinkedit.txt -width 145 -height 3
        wm title .plinkedit "Edit"

        # Use the value from the registry if it exists...
        wm geometry .plinkedit [::appcfg get "plinkpos" "1020x75"]

        # Update size and position on change.
        bind .plinkedit <Configure> {::appcfg set plinkpos [wm geometry .plinkedit] TRUE}
        # Save the size and position of the table of headers when the window is closed/destroyed.
        bind .plinkedit <Destroy> {::appcfg save}

        # make a button frame (so we get the pretty side by side buttons)
        frame .plinkedit.btn
        button .plinkedit.btn.save -text "save"
        button .plinkedit.btn.discard -text "discard" -command [list destroy .plinkedit]
        pack .plinkedit.btn.save .plinkedit.btn.discard -side left

        # Put the form together
        pack .plinkedit.txt -fill both -side top
        pack .plinkedit.btn -side bottom
    } else {
        # the window already exists, bring it the the 'front'.
        raise .plinkedit
    }
    .plinkedit.btn.save configure -command [list plink_save $txtwidget $tag]
    .plinkedit.txt insert 1.0 $edittext
    focus .plinkedit
}


################################################################################
#   Procedure: plink_mtag
#
# Description: Apply 'plink' markup properties/side effects
#
# Parameters
# ==========
# txtwidget         I   txt widget to interact with.
# uniqtag           I   The unique tag assigned by tag_range.
#
# Return Value
# ============
# Empty String.
#
# Error Handling
# ==============
# None.
################################################################################
proc plink_mtag {txtwidget uniqtag} {
    $txtwidget tag bind $uniqtag <Leave> {%W configure -cursor {}}
    # Call plink_reset to set up the block in to the initial state
    plink_reset $txtwidget $uniqtag

    # Keep track of the last location on this txtwidget... set to -1,-1 when the cursor
    # leaves the widget.
    bind $txtwidget <Motion> [list set ::_csrloc($txtwidget) "%x,%y"]
    bind $txtwidget <Leave> [list set ::_csrloc($txtwidget) "-1,-1"]
    return
}


################################################################################
#   Procedure: plink_output
#
# Description: Output window for a completed command.
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc plink_output {txtwidget uniqtag output} {
    if {![winfo exists .${uniqtag}_output]} {
        # The edit window doesn't exist, create it
        toplevel .${uniqtag}_output
        text .${uniqtag}_output.txt
        wm title .${uniqtag}_output "Output"

        # Use the value from the registry if it exists...
        wm geometry .${uniqtag}_output [::appcfg get "plinkoutputpos" "640x480"]

        # Create a copy button...
        button .${uniqtag}_output.btncopy -text "copy"

        # Create a checkbox to toggle highlight of every other line
        checkbutton .${uniqtag}_output.cb -variable ::${uniqtag}_cbval \
                -text "Highlight every other line" -onvalue 1 -offvalue 0 \
                -command [list plink_toggle_hl .${uniqtag}_output.txt ::${uniqtag}_cbval]

        # Add a scrollbar
        ttk::scrollbar .${uniqtag}_output.sb -orient vert
        .${uniqtag}_output.sb configure -command [list .${uniqtag}_output.txt yview]
        .${uniqtag}_output.txt configure -yscrollcommand [list .${uniqtag}_output.sb set]

        # Put the form together
        place .${uniqtag}_output.txt -relheight 1.0 -height -18 -relwidth 1.0 -width -15
        place .${uniqtag}_output.sb -relx 1.0 -x -15 -relheight 1.0 -width 15
        place .${uniqtag}_output.btncopy -relx 0.125 -rely 1.0 -y -18 -height 18
        place .${uniqtag}_output.cb -relx 0.325 -rely 1.0 -y -18 -height 18
    } else {
        # the window already exists, bring it the the 'front'.
        raise .${uniqtag}_output
        focus .${uniqtag}_output
    }
    .${uniqtag}_output.btncopy configure -command "
        clipboard clear
        clipboard append \{$output\}
    "
    .${uniqtag}_output.txt delete 1.0 end
    .${uniqtag}_output.txt insert end $output
    for {set line 1} {$line <= [.${uniqtag}_output.txt count -line 1.0 end]} {incr line} {
        if {[expr {$line % 2}] == 0} {
            .${uniqtag}_output.txt tag add hl ${line}.0 [expr {$line + 1}].0
        }
    }

    .${uniqtag}_output.txt configure -state disabled

}
proc plink_toggle_hl {txtwidget cbvar} {
    upvar $cbvar val
    if {$val} {
        $txtwidget tag configure hl -background #e8e8e8
    } else {
        $txtwidget tag configure hl -background {}
    }
}


################################################################################
#   Procedure: plink_preload
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
proc plink_preload {} {
    if {[winfo exists .plinkedit]} {
        destroy .plinkedit
    }
    unset -nocomplain ::output
    return
}


################################################################################
#   Procedure: plink_reset
#
# Description: Put the plink block in to it's initial state.
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc plink_reset {txtwidget uniqtag} {
    unset -nocomplain ::output($uniqtag)
    catch {destroy .${uniqtag}_output}
    # Nifty little hand while hovering over
    $txtwidget tag bind $uniqtag <Enter> {%W configure -cursor hand2}
    # Orange background
    $txtwidget tag configure $uniqtag -background #E8A053
    #   Middle Click - edit the plink block
    $txtwidget tag bind $uniqtag <Button-2> [list plink_edit $txtwidget $uniqtag]
    #   Left Click - copy line to clipboard, change block's background.
    $txtwidget tag bind $uniqtag <Button-1> [list plink_run $txtwidget $uniqtag]
}


################################################################################
#   Procedure: plink_run
#
# Description:
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc plink_run {txtwidget uniqtag} {
    $txtwidget configure -cursor wait
    set editrange [$txtwidget tag ranges $uniqtag]
    set block [split [$txtwidget get {*}$editrange] \n]

    set puttyCfg [lindex $block 0]
    set cmd [join [lrange $block 1 end] \n]

    $txtwidget configure -state normal
    # Shade to gray
    $txtwidget tag configure $uniqtag -background #69718C
    $txtwidget configure -state disabled

    # Disable bindings while running.
    $txtwidget tag bind $uniqtag <Button-1> {}
    $txtwidget tag bind $uniqtag <Button-2> {}
    $txtwidget tag bind $uniqtag <Double-Button-3> {}
    # Since the bindings are disabled until the the job finishes running, use "wait" for the cursor
    $txtwidget configure -cursor wait
    $txtwidget tag bind $uniqtag <Enter> {%W configure -cursor wait}

    # Start the process in the background, plink_bgjob will monitor for completion
    # and finish up...
    set ch [open "| [list [::appcfg get plink] -load $puttyCfg -batch -agent $cmd]"]
    # Switch to nonblocking in order to keep the GUI responsive while it's running.
    fconfigure $ch -blocking FALSE
    fileevent $ch readable [list plink_bgjob $ch $txtwidget $uniqtag]

    return
}



################################################################################
#   Procedure: plink_save
#
# Description: Save an edit to a plink block
#
# Parameters
# ==========
# txtwidget         I   txt widget to interact with.
# tag               I   tag of original plink block to save.
# plinktext         I   If set, don't look at .plinkedit.txt.  Useful for intial setup.
# copyOnSave        I   If true, copy the plink to the clipboard.  Otherwise
#                       reset the tag background color and clear the clipboard.
#
# Return Value
# ============
# true/false
#
# Error Handling
# ==============
# None.
################################################################################
proc plink_save {txtwidget tag} {

    set editrange [$txtwidget tag ranges $tag]
    set plinktext [.plinkedit.txt get 0.0 end]

    $txtwidget configure -state normal
    $txtwidget delete {*}$editrange

    $txtwidget insert [lindex $editrange 0] $plinktext [list "plink" $tag]
    $txtwidget configure -state disabled

    destroy .plinkedit
}