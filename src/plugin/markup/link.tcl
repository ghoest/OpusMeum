####################################################################################################
#/---------------------------------------
#| Name    link.tcl
#\---------------------------------------
#
# Description
#     Markup Tag {link}
#
# PROCEDURES : link_mtag
#
# VARIABLES  : ::_known_markup  -- used in OpusMeum.tcl
####################################################################################################
lappend ::_known_markup {link}

################################################################################
#   Procedure: link_mtag
#
# Description: Apply 'link' markup properties/side effects
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
proc link_mtag {txtwidget uniqtag} {
    $txtwidget tag configure $uniqtag -foreground blue
    $txtwidget tag bind $uniqtag <Enter> {%W config -cursor hand2}
    $txtwidget tag bind $uniqtag <Leave> {%W config -cursor {}}

    #   Left Click - open link, change block's background.
    $txtwidget tag bind $uniqtag <Button-1> [list twapi::shell_execute -path \
            [string trim [$txtwidget get {*}[$txtwidget tag ranges $uniqtag]]]]
    $txtwidget tag bind $uniqtag <Button-1> \
            +[list $txtwidget tag configure $uniqtag -foreground purple]

    #   Right Click - change block's background.
    $txtwidget tag bind $uniqtag <Button-3> \
            [list $txtwidget tag configure $uniqtag -foreground blue]

    return
}