####################################################################################################
#/---------------------------------------
#| Name    date.tcl
#\---------------------------------------
#
# Description
#     Replacement Tag {date}
#
# PROCEDURES : date_rtag
#
# VARIABLES  : ::_known_rtag -- used in OpusMeum.tcl
####################################################################################################
lappend ::_known_rtag {date}

################################################################################
#   Procedure: date_rtag
#
# Description: return a date given the input...
#
# Parameters
# ==========
# input             I   input for procedure.
#
# The following forms of input are acceptable
#     {"date:" $clkFmt $when}
#     {"date:" $clkFmt}
# $clkFmt can be anything accepted by 'clock format ... -format'
# $when is anything accepted by 'clock scan'
#
# Return Value
# ============
# true/false
#
# Error Handling
# ==============
# None.
################################################################################
proc date_rtag {input} {
    if {[llength $input] == 2} {
        set when [lindex $input 1]
    } else {
        set when "now"
    }
    return [clock format [clock scan $when] -format [lindex $input 0]]
}