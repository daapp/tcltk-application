package require Tk
package require Ttk
package require msgcat

package require snit

package require widget::toolbar
package require widget::statusbar

package require tkapp::preferences



# todo: add configuration storage
# todo: make widget for "About program" dialog, example in glade-gtk
snit::widget tkapp {
    hulltype toplevel

    option -application -configuremethod SetApplication -readonly true
    option -author
    option -icon
    option -manual
    # if -defaultmenu 1, then create default menu at widget construction
    option -defaultmenu -default 1 -readonly true
    option -name
    option -quitcommand -default exit
    option -showconsole -default 0 -type snit::boolean -readonly true
    option -site
    option -statusbar -configuremethod SetStatusbar
    option -title
    option -version
    option -aboutcommand

    delegate option * to hull

    component frame -public frame
    component statusbar -public statusbar
    component toolbar -public toolbar
    component prefs -public prefs
    component menu -public menu

    variable statusBarPackInfo ""


    typeconstructor {
        namespace import ::msgcat::mc
    }


    constructor args {
        $self configurelist $args

        if {$options(-title) eq ""} {
            wm title $win $options(-name)
        } else {
            wm title $win $options(-title)
        }

        install menu using menu $win.appmenu
        if {$options(-defaultmenu)} {
            $self MakeDefaultMenu
        }

        install toolbar using widget::toolbar $win.toolbar
        install frame using ttk::frame $win.frame
        install statusbar using widget::statusbar $win.statusbar

        grid $toolbar -sticky new
        grid $frame -sticky nsew
        grid $statusbar -sticky sew

        grid columnconfigure $win $frame -weight 1
        grid rowconfigure $win $frame -weight 1


	if {[tk windowingsystem] eq "aqua"} {
	    proc ::tk::mac::Quit {} [mymethod quit]
	} else {
    	    bind $win <Control-q> [mymethod quit]
	}
	
        wm protocol $win WM_DELETE_WINDOW [mymethod quit]
    }


    destructor {
    }


    method MakeDefaultMenu {} {
        menu $menu.file -tearoff 0
        $menu.file add command -label [mc "Quit"] -command [mymethod quit] -accelerator {Ctrl+Q}

        menu $menu.help -tearoff 0
        if {$options(-manual) ne ""} {
            $menu.help add command -label [mc "Manual"] -command [mymethod manual]
            $menu.help add separator
        }
        if {[string is true -strict $options(-showconsole)]} {
            $menu.help add command -label [mc "Show console"] -command [mymethod showConsole]
        }
        $menu.help add command -label [mc "About"] \
            -command [expr {$options(-aboutcommand) ne "" ? $options(-aboutcommand) : [mymethod about]}]

        $win.appmenu add cascade -label [mc "File"] -menu $menu.file -underline 0
        $win.appmenu add cascade -label [mc "Help"] -menu $menu.help -underline 0

        $hull configure -menu $menu
    }


    method getframe {} {
        return $frame
    }


    method manual {} {
        if {$options(-manual) ne ""} {
            $self StartBrowser $options(-manual)
        }
    }


    method showConsole {} {
        switch -- $::tcl_platform(platform) {
            windows {
                console show
            }
            unix {
                if {[catch {set tkcon [exec which tkcon]}]} {
                    tk_messageBox -parent . -type ok -icon error \
                        -title [mc "Console is unavaible!"] \
                        -message [mc "Unable to show console.\nInstall tkcon first"]
                } else {
                    exec $tkcon -e "tkcon attach {[tk appname]}" &
                }
            }
            default {
                tk_messageBox -parent . -type ok -icon error \
                    -title [mc "Function is not implemented!"] \
                    -message [mc "Console in not implemented for %s platform." $::tcl_platform(platform)]
            }
        }

    }


    method about {} {
        set message [list $options(-name)]
        lappend message [mc "version %s" $options(-version)]
        lappend message [mc "Copyright (c) %s" $options(-author)]
        if {$options(-site) ne ""} {
            lappend message [mc "Visit %s for more info." $options(-site)]
        }

        tk_messageBox \
            -type ok \
            -icon info \
            -parent $win \
            -message [join $message \n] \
            -title [mc "About %s" $options(-name)]
    }


    method StartBrowser {url} {
        switch -- $::tcl_platform(platform) {
            unix {
                exec xdg-open $url &
            }
            windows {
                exec cmd /c start $url &
            }
        }
    }


    method quit {} {
        set answer [tk_messageBox -type yesno -icon question -parent $win \
                        -title [mc "Quit..."] \
                        -message [mc "Really quit?"]]
        if {$answer eq "yes"} {
            uplevel #0 $options(-quitcommand)
        }
    }


    method SetApplication {option value} {
        set options($option) $value
        install prefs using preferences %AUTO% -application $options(-application)
    }


    method gettoolbar {} {
        return $toolbar
    }


    method getstatusbar {} {
        return $statusbar
    }

    method getmenu {} {
        return $menu
    }


    method SetStatusbar {option value} {
        set options($option) $value
        if {[string is false -strict $value]} {
            set statusBarPackInfo [pack info $statusbar]
            pack forget $statusbar
        } else {
            pack configure $statusbar {*}$statusBarPackInfo
        }
    }


    typevariable Widgets -array {}


    proc w {name {path ""}} {
        if {$path eq ""} {
    	    if {[info exists Widgets($name)]} {
        	return $Widgets($name)
    	    } else {
    		return ""
    	    }
        } else {
            return [set Widgets($name) $path]
        }
    }
}

namespace eval tkapp {namespace export w}
