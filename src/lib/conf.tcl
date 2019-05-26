####################################################################################################
#/---------------------------------------
#| Name    conf.tcl
#\---------------------------------------
#
# Description
#     Package to simplify managing application configuration.
#     This is intended to be a general purpose package, but at the moment is specific to OpusMeum
#
# TODO
#     There is still quite a bit of code that's not fully written.  At the moment, it
#     is assumed that the platform being used is Windows and the registry is used at the
#     storage for the (persisted configuration).
#
# Arguments
#     -app       The application name to use with configuration backing.  Defaults to
#                [file tail [info script]].
#     -base      The base path to use with configuration backing.  Defaults to
#                "\\HKEY_CURRENT_USERS\\Software" or [pwd].
#     -create    Create configuration backing if it does not exist. Defaults to FALSE
#     -env       Used with the "env" type; override process environment with provided values.
#                May be specified more than once {key="value"}; no default.
#     -readonly  Disable save functionality.  Defaults to FALSE.
#     -type      The configuration backing type to use.  Defaults to "registry".
#
# Examples
#        # Use the defaults, and create the configuration backing if it doesn't exist
#        ::configuration create myAppConf -create TRUE
#        myAppConf get "SomeSetting" "" TRUE
#
####################################################################################################
package provide conf {1.0}

package require TclOO
package require registry

################################################################################
# Class: conf
#
# Private Methods
# ============================================
#   Init.registry   "initialize" helper method: load configuration from registry.
#   Save.registry   Save helper method: save configuration to registry.
#
# Public Methods
#   get             Get a value.
#   initialize      Initialize data according to values set in constructor.
#   set             Set a value.
#   save            Save persistent values.
#
# Variables
# =========
#   cfg       dictionary containing configuration settings.
#   pval      Configuration settings that should persist.
#
# Error Handling
# ==============
# None.
################################################################################
oo::class create conf {
    constructor {args} {
        variable cfg
        variable pval
        set pval [list]
        set cfg [dict create]

        set def     [list "app"      [file tail [info script]]]
        lappend def [list "create"   FALSE]
        lappend def [list "env"      [list]]
        lappend def [list "readonly" FALSE]

        if {$::tcl_platform(os) eq "Windows NT"} {
            lappend def [list "base" "HKEY_CURRENT_USER\\Software"]
            lappend def [list "type" "registry"]
        } else {
            lappend def [list "base" [pwd]]
            lappend def [list "type" "file"]
        }

        foreach arg $def {
            set setting [lindex $arg 0]
            set value [lindex $arg 1]
            if {[set idx [lsearch -exact $args "-${setting}"]] != -1} {
                set value [lindex $args [expr {$idx + 1}]]
            }
            dict set cfg "__settings" $setting $value
        }
        my initialize
    }

    destructor {
        # What needs to be done as part of clean up... anything?
    }
}

#################
# Private methods
#################


################################################################################
# Init.registry
#
#     "initialize" helper method; load from registry.
#
# Parameters
#
# None.
#
################################################################################
oo::define conf method Init.registry {path {nest {}}} {
    variable cfg
    if {[catch {registry values $path} values]} {set values ""}
    foreach val $values {
        dict set cfg {*}$nest $val [registry get $path $val]
    }
    if {[catch {registry keys $path} keys]} {set keys ""}
    foreach key $keys {
        my Init.registry "${path}\\${key}" [list {*}$nest $key]
    }
    return
}


################################################################################
# Save.registry
#
#     Recursive procedure to find keys in the dictionary that are also in the
#     key list (klist).
#
# Parameters
#     dname             I   The name of the dictionary to use.
#     klist             I   List of keys to persist.
#     base              I   Base path for the registry key.
################################################################################
oo::define conf method Save.registry {dname klist base} {
    upvar 1 $dname d
    if {[catch {dict keys $d} keys]} {
        return
    }
    set rtn [list]
    foreach key $keys {
        set result [catch {dict get $d $key} current]
        set next [my Save.registry current $klist "${base}\\${key}"]
        if {!$result && ($next eq "") && ($current ne "") && [lsearch -exact $klist $key] != -1} {
            lappend rtn $next
            registry set "${base}" $key $current
        }
    }
    return $rtn
}

################
# Public methods
################

################################################################################
# get
#
#     Return value of a stored key,
#
# Parameters
#     key               I   key to get.
#     def               I   A default value to use when the keys value is empty.
#     persist           I   Flag to indicate if a value should be persisted when
#                           saving application settings.  Note, once set to TRUE,
#                           the value will persist even if subsequent calls use FALSE.
#
# Returns
#     Value of key
################################################################################
oo::define conf method get {key {def ""}} {
    variable pval
    variable cfg
    if {$key eq "*"} {
        return $cfg
    }
    if {[dict exists $cfg {*}$key]} {
        return [dict get $cfg {*}$key]
    } else {
        dict set cfg $key $def
    }
    return $def
}


################################################################################
# initialize
#
#     Initialize configuration data.
#
# Error Handling
#     DNE               The configuration backing does not exist and -create
#                       was not specified.
#     UNKTYPE           The configuration backing type is not known.
################################################################################
oo::define conf method initialize {} {
    variable cfg

    set app  [dict get $cfg "__settings" "app"]
    set base [dict get $cfg "__settings" "base"]
    set type [dict get $cfg "__settings" "type"]

    switch -exact $type {
        "env" {
            foreach key [array names ::env] {
                dict set cfg $key $::env($key)
            }
            if {[dict exists cfg "__settings" "env"]} {
                foreach key [dict get cfg "__settings" "env"] {
                    set idx [string first "=" $key]
                    dict set cfg [string range $key 0 [expr {${idx} - 1}]] \
                            [string range $key $idx end]
                }
            }
        }
        "registry" {
            # Load all the values from the registry
            package require registry
            if {$base eq ""} {
                # Default base location
                set base "HKEY_CURRENT_USER\\Software"
                dict set cfg "__settings" "base" $base
            }
            set rpath "${base}\\${app}"
            if {[catch {registry values $rpath} values]} {
                set create [dict get $cfg "__settings" "create"]
                if {[string is boolean $create] && !$create} {
                    error "Registry entries do not exist (create is FALSE)" "" {DNE}
                }
            }
            my Init.registry ${rpath}
        }
        "file" {
            # Load values stored in the file
            set fname [file join $rpath $app]
            if {[file extension $fname] eq ""} {
                append fname ".conf"
            }
            my Init.file $fname
        }
        default {
            error "Unknown configuration backing type: $type" "" {UNKTYPE}
        }
    }

    return
}


################################################################################
#   Procedure: Update a key's persistence.
#
#     Return value of a stored key,
#
# Parameters
#     key         I  The key
#     save        I  Set to TRUE to make the key persistent, FALSE to make it transient
#
# Error Handling
#     NOT_BOOLEAN    "save" must be TRUE or FALSE.
#     KEY_DNE        The key doesn't exist.
################################################################################
oo::define conf method persist {key save} {
    variable cfg
    variable pval
    if {![string is boolean $save]} {
        error "'save' must be TRUE or FALSE" "" {NOT_BOOLEAN}
    }
    if {![dict exists $cfg {*}$key]} {
        error "The key, $key, was not found" "" {KEY_DNE}
    }
    if {$save} {
        set pval [lsearch -all -not -inline $pval $key]
    } else {
        set pval [list {*}$pval $key]
    }
    set pval [lsort -uniq $pval]

    return
}


################################################################################
# save
#     Save the application configuration settings.
################################################################################
oo::define conf method save {} {
    # NOTE: only save values listed under pval
    variable pval
    variable cfg

    set type [dict get $cfg "__settings" "type"]
    if {$type eq "registry"} {
        # at the moment, only registry settings are saved.
        my Save.registry cfg $pval \
            "[dict get $cfg "__settings" "base"]\\[dict get $cfg "__settings" "app"]"
        return
    }
}



################################################################################
# set
#    Set value of a stored key,
#
# Parameters
#     key               I   key to set.
#     value             I   value to use.
#     persist           I   Flag to indicate if a value should be persisted when
#                           saving application settings.  Note, once set to TRUE,
#                           the value will persist even if subsequent calls use FALSE.
################################################################################
oo::define conf method set {key value {persist FALSE}} {
    variable pval
    variable cfg
    if {$persist} {
        set pval [lsort -uniq [list {*}$pval [lindex $key end]]]
    }
    dict set cfg $key $value

    return
}


###################
# debugging methods
###################
oo::define conf method info {} {
    puts "Configuration  :: [my cfg]"
    puts "Persist Values :: [my pval]"
    puts "Settings       :: [my settings]"
}
oo::define conf method cfg {} {variable cfg; return [dict remove $cfg "__settings"]}
oo::define conf method pval {} {variable pval; return $pval}
oo::define conf method settings {} {variable cfg; return [dict get $cfg "__settings"]}

###########################################
# Procedures that probably belong elsewhere perhaps they belong in "assisTk.tcl"?
###########################################
# bind ... that takes a list of events/tags ...
proc bindL {widget eventList args} {
    set rtn [list]
    foreach event $eventList {
        set temp [bind $widget $event {*}$args]
        if {[llength $args] eq 0} {
            lappend rtn $temp
        } elseif {([llength $args] eq 1) && ($args eq "")} {
            lappend rtn {*}$args
        }
    }
    return $rtn
}