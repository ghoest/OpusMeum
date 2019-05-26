# htext.tcl
# Copied from the Tcler's wiki: http://wiki.tcl.tk/1848
#
set docu(htext) {
Richard Suchenwirth 2001-07-20 - Here's an update to a little hypertext system that you might use for online help. It exports a single command:
 htext::htext (widget) ?title?
brings up a toplevel showing the specified page (or an alphabetic index of titles, if not specified). Thus you can use it for context-sensitive help. You create help pages by just assigning to the global [::docu] array. Links are displayed underlined and blue (or purple if they have been visited before), and change the cursor to a pointing hand. Clicking on a link of course brings up that page. In addition, you get "Index", "Search" (case-insensitive regexp in titles and full text), "History", and "Back" links at the bottom of pages. In a nutshell, you get a tiny browser, an information server, and a search engine ;-) See also [htext format].
}
set {docu(htext format)} {
The htext hypertext pages stored in the [::docu] array are in a subset of Wiki format:
indented lines come in fixed font without evaluation;
blank lines break paragraphs
all lines without leading blanks are displayed without explicit linebreak (but possibly word-wrapped)
a link is the title of another page in brackets (see examples at end).
}
set docu(::docu) {
This global array is used for storing htext pages. The advantage is that source files can be documented just by assigning to ::docu fields, without creating a dependency on htext. After creating a htext widget, all docu documentation is instantly available.
If you wish to have spaces in title, brace the whole thing:
 set {docu(An example)} {...}
}

package require msgcat

namespace eval htext {
    namespace export htext
    variable history {} seen {}
    proc htext {w args} {
        variable historyLabel
        variable searchLabel
        variable indexLabel
        variable backLabel

        if {![winfo exists $w]} {
            wm title [toplevel $w] Help
            text $w.t -borderwidth 5 -relief flat -wrap word \
                    -state disabled -font {Times 9}
            pack $w.t -fill both -expand 1
            set w $w.t
        }

        if {![info exists historyLabel]} {
            set historyLabel [msgcat::mc "History"]
            set searchLabel [msgcat::mc "Search"]
            set indexLabel [msgcat::mc "Index"]
            set backLabel [msgcat::mc "Back"]
        }

        $w tag config centered -justify center
        $w tag config link -foreground blue -underline 1
        $w tag config seen -foreground purple4 -underline 1
        $w tag bind link <Enter> "$w config -cursor hand2"
        $w tag bind link <Leave> "$w config -cursor {}"
        $w tag bind link <1> "[namespace current]::click $w %x %y"
        $w tag config hdr -font {Times 16}
        $w tag config fix -font {Courier 9}
        raise $w
        if {![llength [array names ::docu $args]]} {set args Index}
        show $w $args
    }
    proc click {w x y} {
        variable historyLabel
        variable searchLabel
        variable indexLabel
        variable backLabel
        set range [$w tag prevrange link [$w index @$x,$y]]
        set link [eval $w get $range]
        if {[string equal $link $historyLabel]} {
            set link History
        }  elseif {[string equal $link $searchLabel]} {
            set link Search
        }  elseif {[string equal $link $indexLabel]} {
            set link Index
        }  elseif {[string equal $link $backLabel]} {
            set link Back
        }
        if {[llength $range]} {show $w $link}
    }
    proc back w {
        variable history
        set l [llength $history]
        set last [lindex $history [expr {$l-2}]]
        set history [lrange $history 0 [expr {$l-3}]]
        show $w $last
    }
    proc listpage {w list} {
        foreach i $list {$w insert end \n; showlink $w $i}
    }
    proc search w {
        $w insert end "\n" {} [msgcat::mc "Search phrase:"] {} "  " {}
        entry $w.e -textvariable [namespace current]::search
        $w window create end -window $w.e
        focus $w.e
        $w.e select range 0 end
        bind $w.e <Return> "htext::dosearch $w"
        button $w.b -text [msgcat::mc "Search!"] -command "htext::dosearch $w" -pady 0
        $w window create end -window $w.b
    }
    proc dosearch w {
        variable search
        $w config -state normal
        $w insert end "\n\n" {} [msgcat::mc "Search results for '%s':" $search] {} \n {}
        foreach i [lsort [array names ::docu]] {
            if {[regexp -nocase -- $search $i]} {
                $w insert end \n; showlink $w $i ;# found in title
            } elseif {[regexp -nocase -indices -- $search $::docu($i) pos]} {
                regsub -all \n [string range $::docu($i) \
                        [expr {[lindex $pos 0]-20}] [expr {[lindex $pos 1]+20}]] " " context
                $w insert end \n
                showlink $w $i
                $w insert end " - ...$context..."
            }
        }
        $w config -state disabled
    }
    proc showlink {w link} {
        if {[regexp "^image\\://(.*)\$" $link "" imgname]} {
            set end0 [$w index end]
            $w insert end "\n"
            $w image create end -image $imgname
            $w insert end "\n"
            $w tag add centered $end0 end-1c
            return
        }
        variable seen
        variable historyLabel
        variable searchLabel
        variable indexLabel
        variable backLabel
        set tag link
        if {[lsearch -exact $seen $link]>-1} {
            lappend tag seen
        } else {lappend seen $link}
        if {[string equal $link History]} {
            set link $historyLabel
        }  elseif {[string equal $link Search]} {
            set link $searchLabel
        }  elseif {[string equal $link Index]} {
            set link $indexLabel
        }  elseif {[string equal $link Back]} {
            set link $backLabel
        }
        $w insert end $link $tag
    }
    proc show {w title} {
        variable historyLabel
        variable searchLabel
        variable indexLabel
        variable backLabel
        variable history
        $w config -state normal
        $w delete 1.0 end
        $w insert end $title hdr \n
        switch -- $title {
            Back    {back $w; return}
            History {listpage $w $history}
            Index   {listpage $w [lsort -dictionary [array names ::docu]]}
            Search  {search $w}
            default {
                if {![info exists ::docu($title)]} {
                    $w insert end [msgcat::mc "This page was referenced but not written yet."]
                } else {
                    set var 1
                    foreach i [split $::docu($title) \n] {
                        if {[regexp {^[ \t]+} $i]} {
                            if {$var} {$w insert end \n\n; set var 0}
                            $w insert end $i\n fix
                            continue
                        }
                        set i [string trim $i]
                        if {![string length $i]} {$w insert end \n\n; continue}
                        if {!$var} {$w insert end \n}
                        set var 1
                        while {[regexp {([^[]*)[[]([^]]+)[]](.*)} $i \
                                -> before link after]} {
                            $w insert end "$before " {}
                            showlink $w $link
                            set i $after
                        }
                        $w insert end "$i "
                    }
                }
            }
        }
        $w insert end \n------\n {} $indexLabel link " - " {} $searchLabel link
        if {[llength $history]} {
            if {$title ne "History"} {
                # Don't show the history link on the history page.
                # This deviates from htext found on the Tcler's Wiki.
                $w insert end " - " {} $historyLabel link
            }
            $w insert end " - " {} $backLabel link
        }
        $w insert end \n
	if {$title ne "History"} {
            # It doesn't make much sense to include "History" in the history page.
            # This deviates from htext found on the Tcler's Wiki.
            lappend history $title
	}
        $w config -state disabled
    }
} ;# end namespace htext