####################################################################################################
#/---------------------------------------
#| Name    local.tcl
#\---------------------------------------
#
# Description
#     Markup Tag {local}
#
# PROCEDURES : local_edit
#              local_mtag
#              local_preload
#              local_save
#
# VARIABLES  : ::_before_processing_template  -- used in OpusMeum.tcl
#              ::_known_markup                -- used in OpusMeum.tcl
#              ::appcfg                       -- From OpusMeum.tcl
####################################################################################################
lappend ::_known_markup {local}

# Reset header related variables on template load
lappend ::_before_load_template local_preload


################################################################################
#   Procedure: local_edit
#
# Description: Dialog to edit a local block
#
# Parameters
# ==========
# txtwidget         I   txt widget to interact with.
# tag               I   tag of local block to edit.
#
# Return Value
# ============
# true/false
#
# Error Handling
# ==============
# None.
################################################################################
proc local_edit {txtwidget tag} {

    set editrange [$txtwidget tag ranges $tag]
    set edittext [string trimright [$txtwidget get {*}$editrange]]

    if {![winfo exists .localedit]} {
        # The edit window doesn't exist, create it
        toplevel .localedit
        text .localedit.txt -width 145 -height 3
        wm title .localedit "Edit"

        # Use the value from the registry if it exists...
        wm geometry .localedit [::appcfg get "localpos" "1020x75"]

        # Update size and position on change.
        #bind .localedit <Configure> {::appcfg set localpos [wm geometry .localedit] TRUE}
        # Save the size and position of the table of headers when the window is closed/destroyed.
        #bind .localedit <Destroy> {::appcfg save}

        # make a button frame (so we get the pretty side by side buttons)
        frame .localedit.btn
        button .localedit.btn.save -text "save"
        button .localedit.btn.discard -text "discard" -command [list destroy .localedit]
        pack .localedit.btn.save .localedit.btn.discard -side left

        # Put the form together
        pack .localedit.txt -fill both -side top
        pack .localedit.btn -side bottom
    } else {
        # the window already exists, bring it the the 'front'.
        raise .localedit
    }
    .localedit.btn.save configure -command [list local_save $txtwidget $tag]
    .localedit.txt insert 1.0 $edittext
    focus .localedit
}


################################################################################
#   Procedure: local_mtag
#
# Description: Apply 'local' markup properties/side effects
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
proc local_mtag {txtwidget uniqtag} {
    $txtwidget tag configure $uniqtag -background green
    $txtwidget tag bind $uniqtag <Enter> {%W config -cursor hand2}
    $txtwidget tag bind $uniqtag <Leave> {%W config -cursor {}}
    #   Middle Click - edit the local block
    $txtwidget tag bind $uniqtag <Button-2> [list local_edit $txtwidget $uniqtag]
    #   Left Click - copy line to clipboard, change block's background.
    $txtwidget tag bind $uniqtag <Button-1> [list local_run $txtwidget $uniqtag]

    return
}


################################################################################
#   Procedure: local_preload
#
# Description: perform any work that should be done immediately before a template
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
proc local_preload {} {
    if {[winfo exists .localedit]} {
        destroy .localedit
    }
    unset -nocomplain ::output
    return
}


################################################################################
#   Procedure: local_run
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
proc local_run {txtwidget uniqtag} {
    set editrange [$txtwidget tag ranges $uniqtag]
    set block [split [$txtwidget get {*}$editrange] \n]

    set cmd [join [lrange $block 0 end] \n]

    $txtwidget configure -state normal
    # Shade to gray
    $txtwidget tag configure $uniqtag -background #69718C
    $txtwidget configure -state disabled

    $txtwidget tag bind $uniqtag <Button-1> {}
    # Assumes that we are on Windows
    # Check for commands that are part of the cmd.exe shell, assume anything else should be run directly
    # ... This could probably still stand some improvement
    switch -exact [string tolower [lindex $cmd 0]] {
        "assoc" - "attrib" -
        "break" - "bcdedit" -
        "cacls" - "call" - "cd" - "chcp" - "chdir" - "chkdsk" - "chkntfs" - "cls" - "color" - "comp" - "compact" - "convert" - "copy" -
        "date" - "del" - "dir" - "diskpart" - "doskey" - "driverquery" -
        "echo" - "endlocal" - "erase" - "exit" -
        "fc" - "find" - "findstr" - "for" - "format" - "fsutil" - "ftype" -
        "goto" - "gpresult" - "graftabl" -
        "help" -
        "icacls" - "if" -
        "label" -
        "md" - "mkdir" - "mklink" - "mode" - "more" - "move" -
        "openfiles" -
        "path" - "pause" - "popd" - "print" - "prompt" - "pushd" -
        "rd" - "recover" - "rem" - "ren" - "rename" - "replace" - "rmdir" - "robocopy" -
        "set" - "setlocal" - "sc" - "schtasks" - "shift" - "shutdown" - "sort" - "start" - "subst" - "systeminfo" -
        "tasklist" - "taskkill" - "time" - "title" - "tree" - "type" -
        "ver" - "verify" - "vol" -
        "xcopy" -
        "wmic" {
            set ch [open "| [list cmd /c {*}$cmd] 2>@1"] 
        }
        default {
            set ch [open "| [list {*}$cmd]"]
        }
    }
    
    # Switch to nonblocking in order to keep the GUI responsive while it's running.
    fconfigure $ch -blocking FALSE
    fileevent $ch readable [list local_bgjob $ch $txtwidget $uniqtag]

    return
}

proc local_reset {txtwidget uniqtag} {
    unset -nocomplain ::output($uniqtag)
    catch {destroy .${uniqtag}_output}
    $txtwidget tag bind $uniqtag <Button-1> [list local_run $txtwidget $uniqtag]
    $txtwidget tag configure $uniqtag -background #E8A053
}

proc local_bgjob {chandle txtwidget uniqtag} {
    if {![info exists ::output($uniqtag)]} {
        set ::output($uniqtag) ""
    }
    if {[eof $chandle]} {
        # The running command has completed... set back to blocking, otherwise errors won't
        # be caught on close.
        fconfigure $chandle -blocking TRUE
        set result [catch {close $chandle} err]

        if {$result} {
            append ::output($uniqtag) $err
            set color #F56E7E
#E46878
        } else {
            set color #68F27B
#A9FB51
        }
        $txtwidget configure -state normal
        $txtwidget tag bind $uniqtag <Button-1> \
            [list local_output $txtwidget $uniqtag $::output($uniqtag)]
        $txtwidget tag bind $uniqtag <Double-Button-3> [list local_reset $txtwidget $uniqtag]
        $txtwidget tag configure $uniqtag -background $color
        $txtwidget configure -state disabled
    } else {
        append ::output($uniqtag) [read $chandle]
    }
    return
}

proc local_output {txtwidget uniqtag output} {
    if {![winfo exists .${uniqtag}_output]} {
        # The edit window doesn't exist, create it
        toplevel .${uniqtag}_output
        text .${uniqtag}_output.txt
        wm title .${uniqtag}_output "Output"

        # Use the value from the registry if it exists...
        wm geometry .${uniqtag}_output [::appcfg get "localoutputpos" "1020x240"]

        # make a button frame (so we get the pretty side by side buttons)
        button .${uniqtag}_output.btncopy -text "copy"

                # Create a checkbox to toggle highlight of every other line
        checkbutton .${uniqtag}_output.cb -variable ::${uniqtag}_cbval \
                -text "Highlight every other line" -onvalue 1 -offvalue 0 \
                -command [list local_toggle_hl .${uniqtag}_output.txt ::${uniqtag}_cbval]

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
        clipboard append \"$output\"
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

proc local_toggle_hl {txtwidget cbvar} {
    upvar $cbvar val
    if {$val} {
        $txtwidget tag configure hl -background #e8e8e8
    } else {
        $txtwidget tag configure hl -background {}
    }
}

################################################################################
#   Procedure: local_save
#
# Description: Save an edit to a local block
#
# Parameters
# ==========
# txtwidget         I   txt widget to interact with.
# tag               I   tag of original local block to save.
# localtext         I   If set, don't look at .localedit.txt.  Useful for intial setup.
# copyOnSave        I   If true, copy the local to the clipboard.  Otherwise
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
proc local_save {txtwidget tag} {

    set editrange [$txtwidget tag ranges $tag]

    set localtext [.localedit.txt get 0.0 end]

    $txtwidget configure -state normal
    $txtwidget delete {*}$editrange

    $txtwidget insert [lindex $editrange 0] $localtext [list "local" $tag]
    $txtwidget configure -state disabled

    destroy .localedit
}