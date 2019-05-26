####################################################################################################
#/---------------------------------------
#| Name    command.tcl
#\---------------------------------------
#
# Description
#     Markup Tag {command}
#
# PROCEDURES : command_edit
#              command_mtag
#              command_preload
#              command_save
#
# VARIABLES  : ::_before_processing_template  -- used in OpusMeum.tcl
#              ::_known_markup                -- used in OpusMeum.tcl
#              ::appcfg                       -- From OpusMeum.tcl
####################################################################################################
lappend ::_known_markup {command}

# Reset header related variables on template load
lappend ::_before_load_template command_preload

################################################################################
#   Procedure: command_edit
#
# Description: Dialog to edit a command block
#
# Parameters
# ==========
# txtwidget         I   txt widget to interact with.
# tag               I   tag of command block to edit.
#
# Return Value
# ============
# true/false
#
# Error Handling
# ==============
# None.
#
# TODO
# ====
# This dialog is really basic and doesn't always look right when the user resizes.
################################################################################
proc command_edit {txtwidget tag} {

    set editrange [$txtwidget tag ranges $tag]
    set edittext [string trimright [$txtwidget get {*}$editrange]]

    if {![winfo exists .cmdedit]} {
        # The edit window doesn't exist, create it
        toplevel .cmdedit
        text .cmdedit.txt -width 145 -height 3
        wm title .cmdedit "Edit"

        # Use the value from the registry if it exists...
        wm geometry .cmdedit [::appcfg get "cmdpos" "1020x75"]

        # Update size and position on change.
        bind .cmdedit <Configure> {::appcfg set cmdpos [wm geometry .cmdedit] TRUE}
        # Save the size and position of the table of headers when the window is closed/destroyed.
        bind .cmdedit <Destroy> {::appcfg save}

        # make a button frame (so we get the pretty side by side buttons)
        frame .cmdedit.btn
        button .cmdedit.btn.save -text "save"
        button .cmdedit.btn.saveandcopy -text "save and copy"
        button .cmdedit.btn.discard -text "discard" -command [list destroy .cmdedit]
        pack .cmdedit.btn.save .cmdedit.btn.saveandcopy .cmdedit.btn.discard -side left

        # Put the form together
        pack .cmdedit.txt -fill both -side top
        pack .cmdedit.btn -side bottom
    } else {
        # the window already exists, bring it the the 'front'.
        raise .cmdedit
    }
    .cmdedit.btn.save configure -command [list command_save $txtwidget $tag]
    .cmdedit.btn.saveandcopy configure -command [list command_save $txtwidget $tag "" TRUE]
    .cmdedit.txt insert 1.0 $edittext
    focus .cmdedit
}


################################################################################
#   Procedure: command_mtag
#
# Description: Apply 'command' markup properties/side effects
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
proc command_mtag {txtwidget uniqtag} {
    $txtwidget tag configure $uniqtag -background lightgray
    $txtwidget tag bind $uniqtag <Enter> {%W config -cursor hand2}
    $txtwidget tag bind $uniqtag <Leave> {%W config -cursor {}}
    #   Right Click - clear the clipboard (Appending a blank pushes the 'clear' to
    #                 the OS clipboard.  Usually?) change block's background.
    $txtwidget tag bind $uniqtag <Button-3> [list clipboard clear]
    $txtwidget tag bind $uniqtag <Button-3> +[list clipboard append ""]
    $txtwidget tag bind $uniqtag <Button-3> \
        +[list $txtwidget tag configure $uniqtag -background lightgray]

    #   Middle Click - edit the command block
    $txtwidget tag bind $uniqtag <Button-2> [list command_edit $txtwidget $uniqtag]
    #   Left Click - copy line to clipboard, change block's background.
    set block [$txtwidget get {*}[$txtwidget tag ranges $uniqtag]]
    $txtwidget tag bind $uniqtag <Button-1> [list command_save $txtwidget $uniqtag $block 1]

    return
}


################################################################################
#   Procedure: command_preload
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
proc command_preload {} {
    if {[winfo exists .cmdedit]} {
        destroy .cmdedit
    }
    return
}


################################################################################
#   Procedure: command_save
#
# Description: Save an edit to a command block
#
# Parameters
# ==========
# txtwidget         I   txt widget to interact with.
# tag               I   tag of original command block to save.
# cmdtext           I   If set, don't look at .cmdedit.txt.  Useful for intial setup.
# copyOnSave        I   If true, copy the command to the clipboard.  Otherwise
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
proc command_save {txtwidget tag {cmdtext ""} {copyOnSave FALSE}} {

    set editrange [$txtwidget tag ranges $tag]

    if {$cmdtext eq ""} {
        #checker -scope line exclude warnArgWrite
        set cmdtext [.cmdedit.txt get 0.0 end]
    }

    $txtwidget configure -state normal
    $txtwidget delete {*}$editrange

    # strip out blank lines, remove trailing whitespace from each line.
    #checker -scope line exclude warnArgWrite
    set cmdtext [split $cmdtext \n]
    set cleantext [list]
    for {set idx 0} {$idx < [llength $cmdtext]} {incr idx} {
        set line [string trimright [lindex $cmdtext $idx]]
        if {$line ne ""} {
            lappend cleantext $line
        }
    }
    #checker -scope line exclude warnArgWrite
    set cmdtext [join $cleantext \n]
    # Figure out if the command block continued to the end of the line...
    set lf ""
    if {[lindex [split [lindex $editrange 1] .] 1] == 0} {
        # The block ends just before the first character on the following line...
        set lf "\n";
    }

    $txtwidget insert [lindex $editrange 0] "${cmdtext}${lf}" [list "command" $tag]
    $txtwidget configure -state disabled

    # String leading/trailing whitespace from the command that will be copied to the clipboard
    #checker -scope line exclude warnArgWrite
    set cmdtext [string trim $cmdtext]
    #   Left Click - copy line to clipboard, change block's background.
    $txtwidget tag bind $tag <Button-1> [list clipboard clear]
    $txtwidget tag bind $tag <Button-1> +[list clipboard append $cmdtext]
    $txtwidget tag bind $tag <Button-1> +[list $txtwidget tag configure $tag -background darkgray]

    clipboard clear
    # Appending a blank pushes the 'clear' to the OS clipboard.  Usually?
    clipboard append ""
    if {$copyOnSave} {
        clipboard append $cmdtext
        $txtwidget tag configure $tag -background darkgray
    } else {
        # Clear the previous clipboard entry and put the command block background
        # back to the lighter one to indicate the command has not yet been copied.
        $txtwidget tag configure $tag -background lightgray
    }

    destroy .cmdedit
}