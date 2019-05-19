# vim: filetype=tcl shiftwidth=4 smarttab expandtab
####################################################################################################
# NAME       : mtag_warning.tcl
#
# DESCRIPTION: Markup Tag {warning}
#
# PROCEDURES : warning_mtag
#
# VARIABLES  : ::_known_markup  -- used in OpusMeum.tcl
####################################################################################################
lappend ::_known_markup {warning}

################################################################################
#   Procedure: warning_mtag
#
# Description: Apply 'warning' markup properties/side effects
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
proc warning_mtag {txtwidget uniqtag} {
    $txtwidget tag configure $uniqtag -foreground red

    return
}