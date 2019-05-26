####################################################################################################
#/---------------------------------------
#| Name    copy.tcl
#\---------------------------------------
#
# Description
#     Markup Tag {copy}
#
# PROCEDURES : copy_mtag
#
# VARIABLES  : ::_known_markup  -- used in OpusMeum.tcl
#
####################################################################################################
lappend ::_known_markup {copy}

################################################################################
#   Procedure: copy_mtag
#
# Description: Apply 'copy' markup properties/side effects
#
# Parameters
# ==========
# txtwidget         I   txt widget to interact with.
# uniqtag           I   The unique tag assigned by set_tags.
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc copy_mtag {txtwidget uniqtag} {
    $txtwidget tag configure $uniqtag -background #C8C5AC
    $txtwidget tag bind $uniqtag <Enter> {%W config -cursor hand2}
    $txtwidget tag bind $uniqtag <Leave> {%W config -cursor {}}

    #   Right Click - clear the clipboard (Appending a blank pushes the 'clear' to
    #                 the OS clipboard.  Usually?), change block's background.
    $txtwidget tag bind $uniqtag <Button-3> [list clipboard clear]
    $txtwidget tag bind $uniqtag <Button-3> +[list clipboard append ""]
    $txtwidget tag bind $uniqtag <Button-3> \
            +[list $txtwidget tag configure $uniqtag -background #C8C5AC]

    #   Left Click - copy line to clipboard, change block's background.
    $txtwidget tag bind $uniqtag <Button-1> [list clipboard clear]
    $txtwidget tag bind $uniqtag <Button-1> \
            +[list clipboard append [$txtwidget get {*}[$txtwidget tag ranges $uniqtag]]]
    $txtwidget tag bind $uniqtag <Button-1> \
            +[list $txtwidget tag configure $uniqtag -background #B5B292]

    return
}