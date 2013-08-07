# !/bin/sh
# \
exec tclsh "$0" ${1+"$@"}

tcl::tm::path add lib

package require msgcat
package require tkapp

namespace import msgcat::mcset

mcset ru "File" "Файл"
mcset ru "Quit" "Выход"
mcset ru "Help" "Помощь"
mcset ru "Manual" "Руководство"
mcset ru "About" "О программе"

mcset ru "Really quit?" "Закрыть приложение?"
mcset ru "version %s" "Версия %s"
mcset ru "Visit %s for more info." "Посетите %s для получения дополнительных сведений"

wm withdraw .
tkapp .pm \
    -name "Paint machine" \
    -application PaintMachine \
    -version 0.1 \
    -site github.com \
    -author "Name Surname <email@somewhere.com>" \
    -manual file:///usr/share/doc/tklib/html/index.html \
    -quitcommand {puts quit; exit}
