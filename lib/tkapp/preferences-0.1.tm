if 0 {
    http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
    XDG base directory specification

    Variables:

    - XDG_DATA_HOME :: user specific data files
    - XDG_CONFIG_HOME :: user specific configuration files
    - XDG_DATA_DIRS :: set of preference ordered base directories
                       relative to which data files should be searched

    TODO:
    - [ ] load/save any configuration file from/to configuration directory
}

package require inifile
package require snit

snit::type preferences {
    option -application -default ""

    component ini

    variable appdir
    variable appfile

    constructor args {
        $self configurelist $args
        if {$options(-application) eq ""} {
            error "value for -application can't be empty"
        } else {
            switch -- $::tcl_platform(platform) {
                unix {
                    ::set dir [expr {[info exists ::env(XDG_CONFIG_HOME)] ? $::env(XDG_CONFIG_HOME) : "~/.config/"}]
                    ::set appdir [file join $dir $options(-application)]
                    file mkdir $appdir

                    ::set appfile [file join $appdir $options(-application).ini]
                }
                windows {
                    ::set dir [expr {[info exists ::env(APPDATA)] ? $::env(APPDATA) : $::env(HOME)}]
                    set appdir [file join $dir $options(-application)]
                    file mkdir $appdir

                    set appfile [file join $appdir $options(-application).ini]
                }
                default {
                    error "$type not yet implemented for $::tcl_platform(platform)"
                }
            }
            if {[catch {install ini using ini::open $appfile}]} {
                # this is first start of application
                # create empty
                install ini using ini::open $appfile w+
            }
        }
    }

    destructor {
        ini::close $ini
    }

    method file {} {
        return $appfile
    }

    method dir {} {
        return $appdir
    }


    # save settings to file
    method save {} {
        ini::commit $ini
    }

    method undo {} {
        ini::revert $ini
    }

    method sections {} {
        ini::sections $ini
    }

    method keys {section} {
        ini::keys $ini $section
    }

    method pairs {section} {
        ini::get $ini $section
    }

    method tree {} {
        set t [dict create]
        foreach s [ini::sections $ini] {
            dict set t $s [$self pairs $s]
        }
        return $t
    }

    # args - section {key ""}
    method exists {args} {
        ini::exists $ini {*}$args
    }

    # args - section key ?default?
    method get {args} {
        ini::value $ini {*}$args
    }

    method set {section key value} {
        ini::set $ini $section $key $value
    }

    # args - section ?key?
    method delete {args} {
        ini::delete $ini {*}$args
    }
}
