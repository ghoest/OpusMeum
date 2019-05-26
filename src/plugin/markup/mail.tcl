####################################################################################################
#/---------------------------------------
#| Name    mail.tcl
#\---------------------------------------
#
# Description
#     Markup Tag {mail}
#
# PROCEDURES : mail_fill
#
# VARIABLES  : ::_known_markup  -- used in OpusMeum.tcl
#
####################################################################################################
lappend ::_known_markup {mail}

################################################################################
#   Procedure: mail_fill
#
# Description: convert a "mail" block of text to a mailto uri and pass it to windows
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
proc mail_fill {txtwidget tag} {
    set contentloc [$txtwidget tag ranges $tag]
    set content [split [$txtwidget get {*}$contentloc] \n]

    set mailto [lindex $content 0]
    set subject ""
    set body ""
    set cc ""
    set lastfound ""
    foreach line [lrange $content 1 end] {
        set key [string first "=" $line]
        if {$key != -1} {
            set data [string range $line ${key}+1 end]
            set key [string range $line 0 ${key}-1]
        }
        switch -- $key {
            "body" - "cc" - "subject" {
                #any of body, cc or subject should append the modified line
                append [string tolower $key] [string map {{ } %20} $line]
                set lastfound $key
            }
            default {
                switch -- $lastfound {
                    "body" - "cc" - "subject" {
                        append [string tolower $lastfound] "%0D%0A[string map {{ } %20} $line]"
                    }
                    default {
                        # should this be an error?
                    }
                }
            }
        }
    }
    set uri "mailto:${mailto}?"
    if {$cc ne ""} {
        append uri "${cc}&"
    }
    if {$subject ne ""} {
        append uri "${subject}&"
    }
    if {$body ne ""} {
        append uri "${body}"
    }
    #checker -scope line exclude warnUndefProc
    twapi::shell_execute -path $uri
}


################################################################################
#   Procedure: mail_mtag
#
# Description: Apply 'mail' markup properties/side effects
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
proc mail_mtag {txtwidget uniqtag} {
    $txtwidget tag bind $uniqtag <Enter> {%W config -cursor hand2}
    $txtwidget tag bind $uniqtag <Leave> {%W config -cursor {}}
    $txtwidget tag configure $uniqtag -foreground "#444444" -background "#FFF0C0"
    $txtwidget tag bind $uniqtag <Button-1> [list mail_fill $txtwidget $uniqtag]

    return
}