# vim: filetype=tcl shiftwidth=4 smarttab expandtab
####################################################################################################
# NAME       : mtag_comment.tcl
#
# DESCRIPTION: Markup Tag {comment}
#
# PROCEDURES : comment_mtag
#
# VARIABLES  : ::_known_markup  -- used in OpusMeum.tcl
####################################################################################################
lappend ::_known_markup {comment}

################################################################################
#   Procedure: comment_mtag
#
# Description: Apply 'comment' markup properties/side effects
#
# Parameters
# ==========
# txtwidget         I   txt widget to interact with.
# uniqtag           I   The unique tag assigned by tag_range.
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc comment_mtag {txtwidget uniqtag} {
    $txtwidget delete {*}[$txtwidget tag ranges $uniqtag]

    return
}