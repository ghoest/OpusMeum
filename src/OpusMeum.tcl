#! /bin/env wish
#/---------------------------------------
#| Name    OpusMeum.tcl
#\---------------------------------------
#
# Description 
#     A GUI to present the user with an interactive document (loaded from a template) to peform a
#     set of tasks.
#
# Procedures
#     known_markup
#     known_rtag
#     load_help
#     load_support
#     load_template
#     map_markup
#     search_text
#     set_tags
#
# Variables
#     _appinit
#     _before_load_template
#     _known_markup
#     _known_rtag
#     _tagcnt
#     appcfg
#     appscript
####################################################################################################
# These packages are assumed to exist on auto_path or be included with the tclkit binary in use.
package require http
package require Tcl 8.5
package require Tk

#package require Tclx
# The only proc I'm using from Tclx is readfile... Tclx isn't included with most TclKits, so
# for right now, let's just define readfile here... this should be the same as what appears in Tclx
proc readfile {filename} {
    set fhandle [open $filename]
    set output [read $fhandle]
    close $fhandle
    return $output
}

# Initialization section
set ::appscript [info script]
if {$::appscript eq ""} {
    # If the script is deployed as a wrapped starkit, the output from [info script] will be blank.
    # When wrapped using tclkit, nameofexecutable is an adequate substitute.
    #     http://www.equi4.com/tclkit/index.html
    #     http://code.google.com/p/tclkit/
    set ::appscript [info nameofexecutable]
}

set ::basedir [file dirname $::appscript]

# Add bundled libraries to auto_path and load them
lappend ::auto_path [file join $::basedir "lib"]

# TWAPI provides a tcl interface to the Windows API
package require twapi

# Application helper library
package require app
::app create ::omApp -name "Opus Meum" -version "0.4"

# Configuration library 
package require conf
# Use default registry path structure, by passing empty string as -base.
unset -nocomplain ::appcfg
#checker -scope line exclude warnUndefProc
::conf create ::appcfg -type registry -app [regsub -all { } [::omApp name] {}] -base "" -create TRUE

# If an rtag or mtag type needs anything done before a template is actually loaded,
# then add the procedure to this list.
set ::_before_load_template [list]
# Like above, but just things that need to be once at tail end up of application startup.
set ::_appinit [list]

############
# Procedures
############

################################################################################
#   Procedure: known_markup
#
# Description: Returns true when a markup tag is known, false when it is not.
#              Loaded support files for (markup) tags must append to ::_known_markup
#              in order to enable the tag.
#
# Parameters
# ==========
# tag               I   Tag to validate.
#
# Return Value
# ============
# true/false
#
# Error Handling
# ==============
# None.
################################################################################
set ::_known_markup [list]
proc known_markup {tag} {
    if {[lsearch -exact $::_known_markup $tag] != -1} {
        return true
    }
    return false
}


################################################################################
#   Procedure: known_rtag
#
# Description: Returns true when a replacement tag is known, false when it is not.
#              Loaded support files for (replacement) tags must append to
#              ::_known_rtag in order to enable the tag.
#
# Parameters
# ==========
# tag               I   Tag to validate.
#
# Return Value
# ============
# true/false
#
# Error Handling
# ==============
# None.
################################################################################
set ::_known_rtag [list]
proc known_rtag {tag} {
    if {[lsearch -exact $::_known_rtag $tag] != -1} {
        return true
    }
    return false
}


################################################################################
#   Procedure: load_help
#
# Description: Load "help files" for the htext help menu widget (htext.tcl)
#
#             Copied/modified from Tcler's wiki: http://wiki.tcl.tk/1848
#             note: depends on htext.tcl being loaded.
#
#      Author: Tcler's Wiki Date: 2010/10/12
#
# Parameters
# ==========
# dir              I   The directory to search.
# f_ptn            I   The file pattern to search for.  Defaults to *.{hlp,htp,thf}
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc load_help {dir {f_ptn "*.{hlp,htp,thf}"}} {
    foreach fname [glob -nocomplain -tails -directory $dir -- $f_ptn] {
        if {[catch {open [file join $dir $fname]} fd] == 0 } {
            set idx [file rootname $fname]
            set ::docu(${idx}) [read $fd]
            close $fd
        }
    }
}


################################################################################
#   Procedure: load_support
#
# Description: Load support procedures
#
# Parameters
# ==========
# dlist            I   The directory to search.
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc load_support {dlist} {
    # TODO silently ignoring errors during load... is that such a good idea?
    foreach dir $dlist {
        # markup support
        foreach fname [glob -nocomplain -tails -directory \
		                  [file join $dir "markup"] -- "*.tcl"] {
            if {[catch {source [file join $dir "markup" $fname]} result]} {
            }
        }

        # replacement support
        foreach fname [glob -nocomplain -tails -directory \
		                  [file join $dir "replacement"] -- "*.tcl"] {
            if {[catch {source [file join $dir "replacement" $fname]} result]} {
            }
        }
    }
    # Enable debugging support menu.  Load at start if set to true, don't set if
    # set to false and allow runtime load for any other value.
    #checker -scope line exclude warnUndefProc
    set debug [::appcfg get "debug" "FALSE"]
    if {[string is boolean $debug] && $debug} {
        if {[catch {source [glob -directory [file join $::basedir lib] -- debug.tcl]} result]} {
        }
    } elseif {([string is boolean $debug] && !$debug) || ![string is boolean $debug]} {
        bind . <Control-quoteleft> {
            catch {
                source [glob -directory [file join $::basedir lib] -- debug.tcl]
                bind . <Control-quoteleft> {}
                #checker -scope line exclude warnUndefProc
                debug_init
            }
        }
    }
}


################################################################################
#   Procedure: load_template
#
# Description: Load a template file in to the text widget
#
# Parameters
# ==========
# txtwidget         I   The text widget that the template should be loaded in to.
# template          I   The filename of the template to load; if left as "", then
#                       an "Open File" dialog box is displayed.
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc load_template {txtwidget {template ""}} {
    if {$template eq ""} {
        #checker -scope line exclude warnArgWrite
        set template [tk_getOpenFile -filetypes \
                [list [list "Template files" ".tmpl"] [list "All Files" *]]]
        if {$template ne ""} {
            #checker -scope line exclude warnArgWrite
            set template [readfile $template]
        }
    } else {
        if {[string range [string tolower $template] 0 4] eq "http:"} {
            # Special handling for http links... retrieve a copy to local, delete it on exit
            set result [http::geturl $template]
            #checker -scope line exclude warnArgWrite warnVarRef
            set template [lindex [array get $result "body"] 1]
            http::cleanup $result
        } elseif {[file exists $template]} {
            #checker -scope line exclude warnArgWrite
            set template [readfile $template]
        }
    }

    if {$template eq ""} {
        return
    }

    # Handle any preload work
    foreach procedure $::_before_load_template {
        $procedure
    }

    # 'reset' global variables that should not persist.
    unset -nocomplain ::_tagcnt
    $txtwidget tag delete {*}[$txtwidget tag names]

    #checker -scope line exclude warnUndefProc
    set user [env_rtag "user"]

    # Remove any spaces from the username
    regsub -all { } $user {} user

    # Put the text widget in to a modifiable state and clear the current contents.
    $txtwidget configure -state normal
    $txtwidget delete 1.0 end

    # Variables to track state...
    set linecnt 0
    set cur_block [list]
    set looking false
    set starttag ""

    # Legacy user name tag...
    #checker -scope line exclude warnArgWrite
    regsub -all {\(USER\)} $template $user template
    #checker -scope line exclude warnArgWrite
    regsub -all {\(intl\)} $template $user template
    unset -nocomplain mu
    map_markup template mu
    $txtwidget insert end $template
    # Set the tags on the text.  No modification to the text should be made until this is complete.
    # This code does not support nesting blocks... not currently needed.
    for {set r 0} {$r < [llength $mu]} {incr r 4} {
       set chunk [lrange $mu $r ${r}+3]
       if {[llength $chunk] != 4} {
           catch {$txtwidget get [lindex $chunk 1]} detail
           error "Issue applying markup; additional detail that may be useful: $detail" "" {TAG_ERR}
       }
       set tag [lindex $chunk 1]
       if {$tag ne [lindex $chunk 3]} {
           catch {$txtwidget get $tag} detail
           error "Unexpected tag, $tag; additional detail that may be useful: $detail" "" {TAG_ERR}
       }
       set_tags $txtwidget $tag [lindex $chunk 0] [lindex $chunk 2]
    }

    # Apply properties on the text.
    foreach utag [$txtwidget tag names] {
        if {[set idx [string first "_" $utag]] != -1} {
            [string range $utag 0 $idx]mtag $txtwidget $utag
        }
    }

    # Revert the text widget back to being unmodifiable
    $txtwidget configure -state disabled

    return
}


################################################################################
#   Procedure: map_markup
#
# Description: Build a Markup Map from data and remove markup from data.
#
# Parameters
# ==========
# data         I/O  Name of the variable containing the data to map and clean.
# map          I/O  Name of the variable to return the markup map in.
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
#  1.  BAD_TAG - The tag specified is for internal use only; the procedure takes an
#                argument to indicate if the tags are "auto" generated.
################################################################################
proc map_markup {data map} {
    upvar 1 $data mudata
    upvar 1 $map mumap
    set mumap [list]
    set linecnt 1
    set setup 1
    foreach line [split $mudata \n] {
        if {$setup} {
            set setup 0
            set mudata ""
        }
        set lastcheck 0
        while {1} {
            set start [string first "\{" $line $lastcheck]
            if {$start == -1} {
                break
            } else {
                set stop [string first "\}" $line $start]
                if {[string index $line ${start}+1] eq "/"} {
                    set line "[string range $line 0 ${start}][string range $line ${start}+2 end]"
                    set lastcheck [expr {$start + 2}]
                    unset stop
                    continue
                }
                if {$stop == -1} {
                    # Couldn't find a closing brace on the same line, so leave it alone
                    break
                }
            }
            if {![info exists stop]} {
                break
            }
            set lastcheck $stop
			set mu [string range $line ${start}+1 ${stop}-1]
            set replacement [string range $mu 0 [string first ":" $mu]-1]
            if {($replacement != "") && ([llength [info commands "${replacement}_rtag"]] != 0)} {
                # This is a replacement tag
                set arguments [string range $mu [expr {[string first ":" $mu] + 1}] end]
                set rs [${replacement}_rtag $arguments]
                set line "[string range $line 0 ${start}-1]${rs}[string range $line ${stop}+1 end]"
                # Adjust lastcheck position... simply backup to the first brace of the tag replaced.
                set lastcheck [expr {$start - 1}]
            } elseif {[known_markup $mu]} {
                # This is a known block tag
                set line "[string range $line 0 ${start}-1][string range $line ${stop}+1 end]"
                lappend mumap "${linecnt}.${start}" $mu
                if {$line eq ""} {
                    # This only contained tag for the block...  Skip adding the content of the line
                    set skip 1
                }
                # Adjust the lastcheck position to account for removed brace
                set lastcheck [expr {$start - 1}]
            }
        }
        if {[info exists skip]} {
            unset skip
        } else {
            append mudata "${line}\n"
            incr linecnt
        }
        set mu ""
    }
    return
}


################################################################################
#   Procedure: search_text
#
# Description: Search the textwidget for the specified text and "jump" to it if
#              found.
#
#              Several useful bits of information on searching a text widget can
#              be found at: http://wiki.tcl.tk/17286
#                      and: http://wiki.tcl.tk/15612
#
# Parameters
# ==========
# None.
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc search_text {} {

    if {![winfo exists .search]} {
        # The search window doesn't exist, create it

        # create a search window
        toplevel .search

        entry .search.entry -textvariable find
        pack .search.entry
        bind .search.entry <Return> {
            # Clear out old search tags
            foreach {start stop} [.txt tag ranges "search"] {
                .txt tag remove "search" $start $stop
            }

            set match [.txt search -nocase -count len -- $find "insert + 2c"]
            if {$match ne ""} {
                .txt see $match
                .txt mark set insert $match
                #checker -scope line exclude warnUndefinedVar
                .txt tag add "search" $match "${match} + ${len}c"
                .txt tag configure "search" -background yellow
            }
        }
        bind .search.entry <Destroy> {
            # Clear out old search tags
            foreach {start stop} [.txt tag ranges "search"] {
                .txt tag remove "search" $start $stop
            }
        }

        focus .search.entry
    } else {
        # the window already exists, bring it the the 'front'.
        raise .search
        focus .search.entry
    }
    return
}


################################################################################
#   Procedure: set_tags
#
# Description: Adds tags to a range of text.
#
#              Creates the ::_tagcnt array; which should be wiped whenever a
#              template is loaded/openned.
#
# Parameters
# ==========
# txtwidget         I   The text widget that the template should be loaded in to.
# tag               I   Tag to use for applying formatting rules.
# start             I   Start index of text to tag.
# end               I   End indec of text to tag.
#
# Return Value
# ============
# The unique tag assigned to the text range.
#
# Error Handling
# ==============
################################################################################
proc set_tags {txtwidget tag start end} {

    if {![info exists ::_tagcnt($tag)]} {
        set ::_tagcnt($tag) 0
    }
    incr ::_tagcnt($tag)
    set uniq_tag ${tag}_$::_tagcnt($tag)
    $txtwidget tag add $tag $start $end
    $txtwidget tag add $uniq_tag $start $end

    return $uniq_tag
}


################################################################################
# MAIN
################################################################################

# Load htext source
source [file join $::basedir "lib" "htext.tcl"]

# Load support libraries; rtag, tag related.
# TODO: should tag related stuff be placed in packages?
load_support [list [file join $::basedir "plugin"] \
                   [file join $::basedir .. "plugin"]]

# Load the application help files.
load_help [file join $::basedir "help"]

# Set the window title
wm title . [::omApp name]

# Set the window size...
wm geometry . [::appcfg get "pos" "1035x400"]

# Create the text widget and disable modification
text .txt
.txt configure -state disabled

# Add a scrollbar
ttk::scrollbar .sb -orient vert
.sb configure -command {.txt yview}
.txt configure -yscrollcommand {.sb set}

# Position the text widget and scrollbar on the mainwindow.
place .txt -relheight 1.0 -height 0 -relwidth 1.0 -width -15
place .sb -relx 1.0 -x -15 -relheight 1.0 -width 15

#############################
# Main application menu setup
#############################
menu .mb
. configure -menu .mb

########
# Create the "File" menu tree
########
menu .mb.mfile -tearoff 0
.mb add cascade -menu .mb.mfile -label "File"
.mb.mfile add command -label "Open..." -command {load_template .txt}

# Populate the "Open Link" menu
menu .mb.mopenlink -tearoff 0
set links [dict keys [::appcfg get "Links"]]
foreach key $links {
    set link [string trim [::appcfg get [list Links $key]]]
    # Skip links that are "commented out"
    if {[string index $link 0] ne "#"} {
        .mb.mopenlink add command -label $key -command [list load_template .txt $link]
    }
}
unset -nocomplain key link
if {[llength $links] > 0} {
    # only create this menu if there are any links
    .mb.mfile add cascade -menu .mb.mopenlink -label "Open Link"
}

# End the "File" menu with an Exit choice
.mb.mfile add command -label "Exit" -command {
    exit 0
}

########
# Create the "Tools" menu tree
########
menu .mb.mtools -tearoff 0
.mb add cascade -menu .mb.mtools -label "Tools"
# TODO jg: I plan on this menu being populated with "tools" that may be loaded from
#          the users lib directory (or the embedded lib directory; which happens to
#          be the same directory when this script is run from wish)... at the moment,
#          it'll have a few things hacked directly in here.

# Links to start PuTTY sessions stored in the registry; does not appear if none found.
if {![catch {
	::conf create ::putty -app "SimonTatham\\PuTTY" -readonly TRUE
} result]} {
    ::appcfg set putty [file join "C:/" "Program Files" "PuTTY" "putty.exe"]
    set sessions [dict keys [::putty get "Sessions"]]
    menu .mb.mputty -tearoff 0
    if {[llength $sessions] > 0} {
        foreach session $sessions {
            puts "Session: $session"
            .mb.mputty add command -label $session -command \
                [list exec [::appcfg get putty] -load $session &]
        }
        .mb.mtools add cascade -menu .mb.mputty -label "Putty"
    }
}
########
# Create the "Find" menu tree
########
menu .mb.mfind -tearoff 0
.mb add cascade -menu .mb.mfind -label "Find"
.mb.mfind add command -label "Search..." -command {search_text}

########
# Create the "Help" menu tree
########
menu .mb.mhelp -tearoff 0
.mb add cascade -menu .mb.mhelp -label "Help"
.mb.mhelp add command -label "[::omApp name] help" -command {
    ::htext::htext .h [file rootname [file tail $::appscript]]
}
.mb.mhelp add command -label "About help" -command {::htext::htext .h htext}
.mb.mhelp add command -label "About" -command {
    tk_messageBox -title "About" -type ok \
            -message "[::omApp name] [::omApp version]\n\n    Tcl[info patchlevel] / Tk[package versions Tk]"
}

######################
# Application bindings
######################

# Disable "Copy" binding in text widget.
#checker -scope line exclude warnUndefProc
bindL .txt {<Control-c> <Control-Insert> <Control-x> <Shift-Delete>} {break}
# To enable, use
#bindL .txt {<Control-c> <Control-Insert> <Control-x> <Shift-Delete>} {}
# Update pos when window size/position changes.
bind . <Configure> {::appcfg set "pos" [wm geometry .] TRUE}
bind . <Destroy> {
    ::appcfg save
    ::appcfg destroy
}
# Good ol' find shortcut
bind . <Control-f> {search_text}

# Run initialization code for "plug-ins"
foreach initcmd $::_appinit {{*}$initcmd}
unset -nocomplain initcmd
