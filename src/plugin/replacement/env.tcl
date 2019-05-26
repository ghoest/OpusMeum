####################################################################################################
#/---------------------------------------
#| Name    env.tcl
#\---------------------------------------
#
# Description
#     Replacement Tag {env}
#
# PROCEDURES : env_rtag
####################################################################################################
lappend ::_known_rtag {env}

################################################################################
#   Procedure: env_rtag
#
# Description: Return value of an environment variable.  A default value can be
#              included for use if the env variable does not exist; if all else
#              fails, an empty string is returned.
# Parameters
# ==========
# input             I   input for procedure.
#
# Return Value
# ============
# Value of environment variable, a default or an empty string. (see description)
#
# Error Handling
# ==============
# None.
################################################################################
proc env_rtag {input} {
    set var [lindex $input 0]
    set rtn ""
    set def ""
    if {[llength $input] == 2} {
        set def [lindex $input 2]
    }
    switch -exact -- [string tolower $var] {
        "user" {
            set rtn "Anonymous"
            if {[info exists ::tcl_platform(user)]} {
                set rtn $::tcl_platform(user)
            } elseif {[info exists ::env(USERNAME)]} {
                set rtn $::env(USERNAME)
            }
        }
        default {
            if {[info exists ::tcl_platform($var)]} {
                set rtn $::tcl_platform($var)
            } elseif {[info exists ::env($var)]} {
                set rtn $::env($var)
            }
        }
    }
    if {$rtn eq ""} {
        set rtn $def
    }
    return $rtn
}