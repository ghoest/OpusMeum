###############################################################################
# app.tcl
#========
# Package to simplify of the common functions used by an application
package provide app {1.0}

package require TclOO

oo::class create app {
    constructor {args} {
		set arg_list [list]
		lappend arg_list [list name    "Untitled Application"]
		lappend arg_list [list version "Not Set"]
				
		foreach arg $arg_list {
            set argument [lindex $arg 0]
			variable $argument
            if {[set idx [lsearch -exact $args "-${argument}"]] != -1} {
                set value [lindex $args [expr {$idx + 1}]]
            } else {set value [lindex $arg 1]}
			set $argument $value
        }
	}
	
	destructor {
	    # TODO: is there anything that needs to be done
	}
}

#####
# methods to return information for application
#     -- name
#     -- version
oo::define app method name {} {
    variable name
	return $name
}

oo::define app method version {} {
    variable version
	return $version
}

#####
# Save/Load related functions
#####
oo::define app method save {args} {
    if {$args eq ""} {
	    my Save.save
	    return
	}
	
	set function [string tolower [lindex $args 0]]
	if {[llength $args] < 1} {
	    set arguments [lrange $args 1 end]
	} else {
	    set arguments ""
	}
	
	switch -exact $function {
	    "settings" {
		    puts "this should return some info rather than print to stdout"
		}
		default {
		    error "Unknown 'save' function: $function" "" {UNKNOWN_SAVE_FUNCTION}
		}
	}
	
	return
}

oo::define app method Save.save {} {
    # TODO write the log to do the actual saving
	
	return
}


#####
# Configuration related functionality
#####
# public wrapper methods
#   get
#   set
#   unset
#   persist
#   info
#   vars
oo::define app method conf {function args} {

    switch -exact [string tolower $function] {
	    "get" -
		"persist" -
		"set" -
		"unset" {
		    my Conf.[string tolower $function] {*}$args
		}
		"info" -
		"vars" {
		    set varlist [list "configuration" "persistent"]
			foreach var $varlist {
			    variable $var
				if {[info exists $var]} {
					puts "$var :: [set $var]"
				}
			}
		}
		default {
		    error "Unknown 'conf' function: $function" "" {UNKNOWN_CONF_FUNCTION}
		}
	}
	
	return
}


oo::define app method Conf.get {key {defval ""}} {
    variable configuration
    if {$key eq "*"} {
	    # Check for special case of * for the key... * to return them all
		if {[info exists "configuration"]} {
		    return $configuration
		}
		return
	}
	if {[dict exists $configuration {*}$key]} {
	    return [dict get $configuration {*}$key]
	} else {
	    dict set configuration {*}$key $defval
	}
	return $defval
}
oo::define app method Conf.persist {key {flag TRUE}} {
    variable configuration
	variable persistent
    if {$flag} {
	    if {$key eq "*"} {
		    set persistent [dict keys $configuration]
		} else {
		    lappend persistent $key		
		}
	} else {
	    if {$key eq "*"} {
		    set persistent [list]
		} else {
		    set persistent [lsearch -all -exact -inline -not $persistent $key]
		}
	}
	set persistent [lsort -unique $persistent]
	
	return
}
oo::define app method Conf.set {key value} {
    variable configuration
	dict set configuration {*}$key $value
	
	return
}
oo::define app method Conf.unset {key} {
    variable configuration
	if {[dict exists $configuration {*}$key]} {
	    dict unset configuration {*}$key
	}
	
	return
}