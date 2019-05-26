####################################################################################################
#/---------------------------------------
#| Name    example.tcl
#\---------------------------------------
#
# Description
#     Markup Tag {example}
#
# PROCEDURES : example_mtag
#
# VARIABLES  : ::_known_markup  -- used in OpusMeum.tcl
#
####################################################################################################
lappend ::_known_markup {example}

################################################################################
#   Procedure: example_mtag
#
# Description: Apply 'example' markup properties/side effects
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
proc example_mtag {txtwidget uniqtag} {
    # Use a light blue-ish color in the background for example text
    $txtwidget tag configure $uniqtag -background "#6699BB"

    return
}