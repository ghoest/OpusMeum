####################################################################################################
#/---------------------------------------
#| Name    header.tcl
#\---------------------------------------
#
# Description
#     Markup Tag {header}
#
# PROCEDURES : header_link
#              header_mtag
#              header_preload
#              open_toh
#              tag_jump
#
# VARIABLES  : ::_appinit                     -- used in OpusMeum.tcl
#              ::_before_processing_template  -- used in OpusMeum.tcl
#              ::_known_markup                -- used in OpusMeum.tcl
#              ::_links_tags
#              ::_tagcnt                      -- From OpusMeum.tcl
#              ::appcfg                       -- From OpusMeum.tcl
#
# TODO JG: should some/all of the 'global' variables be stored using config (::appcfg)
####################################################################################################
lappend ::_known_markup {header}

# Reset header related variables on template load
lappend ::_before_load_template header_preload

# Things to do at the end of gui creation.  If dependencies are needed in the plug in
# infrastructure, then some type of priority handling will need to be added
lappend ::_appinit {.mb.mfind add command -label "Table of Headers" -command {open_toh}}

################################################################################
#   Procedure: header_link
#
# Description: Apply 'header_link' markup properties/side effects
#              (header_link should only be generated by code)
#
# Parameters
# ==========
# txtwidget         I   txt widget to interact with.
# uniqtag           I   The unique tag assigned by tag_range.
#
# Return Value
# ============
# Empty String. (would be the name of a procedure to finish applying any changes if there was one)
#
# Error Handling
# ==============
# None.
################################################################################
proc header_link_mtag {txtwidget uniqtag} {

    # Internal use tag, should not appear in  _known_markup
    $txtwidget tag bind $uniqtag <Enter> {%W config -cursor hand2}
    $txtwidget tag bind $uniqtag <Leave> {%W config -cursor {}}
    $txtwidget tag configure $uniqtag -foreground blue
    # Left Click
    $txtwidget tag bind $uniqtag <Button-1> [list tag_jump [regsub {_link} $uniqtag {}]]

    return
}


################################################################################
#   Procedure: header_mtag
#
# Description: Apply 'header' markup properties/side effects
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
proc header_mtag {txtwidget uniqtag} {
    $txtwidget tag configure $uniqtag -justify center -underline true
    set block [$txtwidget get {*}[$txtwidget tag ranges $uniqtag]]
    dict set ::_link_tags "header" $uniqtag [string trim $block]

    return
}


################################################################################
#   Procedure: header_preload
#
# Description: perform any work that should be done immeadiately before a template
#              is loaded.
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc header_preload {} {
    unset -nocomplain ::_link_tags

    if {[winfo exists .toh]} {
        destroy .toh
    }
    return
}


################################################################################
#   Procedure: open_toh
#
# Description: builds/displays the Table of Headers window
#
# Parameters
# ==========
# None.
#
# Return Value
# ============
# None.
#
#open_toh Error Handling
# ==============
# None.
################################################################################
proc open_toh {} {
    if {![info exists ::_link_tags]} {
        return
    }
    if {![winfo exists .toh]} {
        # The search window doesn't exist, create it

        if {[info exists ::_tagcnt(header_link)]} {
            array unset ::_tagcnt header_link
        }

        # create the window
        toplevel .toh
        text .toh.txttoh
        wm title .toh "Table of Headers"

        # Set the size/position based on the default if the value is not stored in the registry.
        wm geometry .toh [::appcfg get "tohpos" "640x480"]

        # Update size and position on change.
        bind .toh <Configure> {::appcfg set "tohpos" [wm geometry .toh] TRUE}
        # Save the size and position of the table of headers when the window is closed/destroyed.
        bind .toh <Destroy> {::appcfg save}

        # Disable copy in text widget.
        foreach shrtct {<Control-c> <Control-Insert> <Control-x> <Shift-Delete>} {
            bind .toh.txttoh $shrtct {break}
        }

        # Add a scrollbar
        ttk::scrollbar .toh.sb -orient vert
        .toh.sb configure -command {.toh.txttoh yview}
        .toh.txttoh configure -yscrollcommand {.toh.sb set}

        place .toh.txttoh -relheight 1.0 -height 0 -relwidth 1.0 -width -15
        place .toh.sb -relx 1.0 -x -15 -relheight 1.0 -width 15

        .toh.txttoh insert 0.0 "Table of Headers\n\n"

        set i 1
        #checker -scope block exclude warnUndefinedVar
        dict for {order block} [dict get $::_link_tags "header"] {
            set loc [expr {[.toh.txttoh index end] - 1}]
            # Only use the first line from the block in the table ...
            .toh.txttoh insert end "${i}: [string trim [lindex [split $block \n] 0]]\n"
            set utag [set_tags .toh.txttoh "header_link" ${loc} end]
            header_link_mtag .toh.txttoh $utag
            incr i
        }


        # Disable writing to the widget
        .toh.txttoh configure -state disabled

        focus .toh
    } else {
        # the window already exists, bring it the the 'front'.
        raise .toh
        focus .toh
    }
}


################################################################################
#   Procedure: tag_jump
#
# Description: Jump to the specified tag
#
# Parameters
# ==========
# tag               I   The tag to jump to in the text.
#
# Return Value
# ============
# None.
#
# Error Handling
# ==============
# None.
################################################################################
proc tag_jump {tag} {
    set loc [lindex [.txt tag nextrange $tag "0.0"] 0]
    .txt see $loc
}