#!/bin/sh
# This comment extends to the next line for tcl \
exec ucpwish $0 $*
#exec ups /opt/antelope/dev/bin/ucpwish -a "$0 $*"
 
set tcl_precision  17
set auto_path [linsert $auto_path 0 /opt/antelope/dev/data/tcl/ucp]
lappend auto_path /opt/antelope/dev/data/tcl/library
auto_load tkerror

global MainWin
global MsgWin               
global but_descr
global anzawin
global gainwin
global daswin
global dcwin
global dccmdwin
global Pfile
global Font8
global Font10
global Font12
global Font14
global Font16
global archive_msg
global cmdhistory
global cmdscroll
global crnt_cmd
 
set Font8 -*-palatino-bold-r-normal-*-8-80-*-*-*-*-*-*
set Font10 -*-palatino-bold-r-normal-*-10-100-*-*-*-*-*-*
set Font12 -*-palatino-bold-r-normal-*-12-120-*-*-*-*-*-*
set Font14 -*-palatino-bold-r-normal-*-14-140-*-*-*-*-*-*
set Font16 -*-palatino-bold-r-normal-*-16-160-*-*-*-*-*-*

set Program ucp
set MainWin .ucp
set pfile "ucp.pf"
set MsgWin ""
set HlpTxt "Push mouse Button2 to get help on command.\n Pust mouse Button1 to select command"
#
set maxcmd 50
set crnt_cmd 0
set anzawin 0
set daswin 0
set dcwin 0
set dccmdwin 0
set gainwin 0
# 
wm withdraw .
toplevel $MainWin
wm title $MainWin "USER CONTROL INTERFACE" 
#
  if {$argc > 0}  {
     for {set i 0} {$i < $argc} {incr i} {
         set arg [lindex $argv $i]
         switch -- $arg {
              -dc {
                  incr i
                  if( $i >= $argc)  {
                       puts "$argv0: neeed argument for -dc\n"
                       puts "usage: ucp [-dc dc_ip_add] [-pf parameter_file]\n"
                       exit 1
                  }
                  set dcname [lindex $argv $i]
               }
              -pf {
                  incr i
                  if( $i >= $argc)  {
                       puts "$argv0: neeed argument for -pf\n"
                       puts "usage: ucp [-dc dc_ip_add] [-pf parameter_file]\n"
                       exit 1
                  }
                  set pfile [lindex $argv $i]
               }
               default {
                       puts "$argv0: unknownd argument '$arg'\n"
                       puts "usage: ucp [-dc dc_ip_add] [-pf parameter_file]\n"
                       exit 1
               }
          }
     }
  }

# Read parameter file
 
  if { [catch "pfgetarr but_descr @$pfile#ButDes" error] } {
        set pfile $argv0
  }
  pfgetarr but_descr @$pfile#ButDes

# get orb name for parameter file 

  if { [catch "pfget $pfile OrbName" error] } {
       set orb "localhost"
  } else {
       set orb "[pfget $pfile OrbName]"
  } 
#puts "$orb"
#
# get DC name from parameter file 
#
  if { [catch "pfget $pfile DcName" error] } {
       set dcname ""
  } else {
       set dcname [pfgetlist @$pfile#DcName]
  } 

set Pfile $pfile

#puts "$dcname"

# set widgets 
 
frame $MainWin.ucp -relief ridge -bg DarkSeaGreen -bd 4 
 
button $MainWin.ucp.vipf \
 -font $Font14 -text "VIEWPF" -bd 2 \
 -activebackground red -bg IndianRed -command " vipf $Pfile "

bind $MainWin.ucp.vipf <Leave> { $MsgWin configure -text $HlpTxt }
bind $MainWin.ucp.vipf <Button-2> { $MsgWin configure -text $but_descr(VIEWPF) }

button $MainWin.ucp.anzapar \
 -font $Font14 -text "ANZADP" -bd 2 -relief raised \
 -activebackground red -bg IndianRed -command "anzadp $orb"
 
bind $MainWin.ucp.anzapar <Leave> { $MsgWin configure -text $HlpTxt }
bind $MainWin.ucp.anzapar <Button-2> { $MsgWin configure -text $but_descr(ANZADP) }

button $MainWin.ucp.daspar \
 -font $Font14 -text "DASPAR" -bd 2 -relief raised \
 -activebackground red -bg IndianRed -command "daspar $orb"
 
bind $MainWin.ucp.daspar <Leave> { $MsgWin configure -text $HlpTxt }
bind $MainWin.ucp.daspar <Button-2> { $MsgWin configure -text $but_descr(DASPAR) }

button $MainWin.ucp.gain \
 -font $Font14 -text "SHOW_GAIN" -bd 2 -relief raised \
 -activebackground red -bg IndianRed -command "gainpar $orb"
 
bind $MainWin.ucp.gain <Leave> { $MsgWin configure -text $HlpTxt }
bind $MainWin.ucp.gain <Button-2> { $MsgWin configure -text $but_descr(SHOW_GAIN) }

button $MainWin.ucp.dcpar \
 -font $Font14 -text "DCPAR" -bd 2 -relief raised \
 -activebackground red -bg IndianRed -command "dcpar $orb"
 
bind $MainWin.ucp.dcpar <Leave> { $MsgWin configure -text $HlpTxt }
bind $MainWin.ucp.dcpar <Button-2> { $MsgWin configure -text $but_descr(DCPAR) }

button $MainWin.ucp.dccmd \
 -font $Font14 -text "COMMAND" -bd 2 -relief raised \
 -activebackground red -bg IndianRed -command "dccmd"
 
bind $MainWin.ucp.dccmd <Leave> { $MsgWin configure -text $HlpTxt }
bind $MainWin.ucp.dccmd <Button-2> { $MsgWin configure -text $but_descr(COMMAND) }

button $MainWin.ucp.radcmd \
 -font $Font14 -text "RADIOCMD" -bd 2 -relief raised \
 -activebackground red -bg IndianRed -command "radcmd "
 
bind $MainWin.ucp.radcmd <Leave> { $MsgWin configure -text $HlpTxt }
bind $MainWin.ucp.radcmd <Button-2> { $MsgWin configure -text $but_descr(RADCMD) }

#      $MainWin.ucp.anzapar

 
pack $MainWin.ucp.vipf \
     $MainWin.ucp.anzapar \
     $MainWin.ucp.daspar \
     $MainWin.ucp.gain \
     $MainWin.ucp.dcpar \
     $MainWin.ucp.dccmd \
     $MainWin.ucp.radcmd \
     -side left -padx 2m -pady 2m -fill both -expand 1
 
frame $MainWin.msg -relief ridge -bg DarkSeaGreen -bd 4 

button $MainWin.msg.quit \
 -font $Font14 -text "QUIT" -bd 3 -relief raised\
 -activebackground red -bg IndianRed -command "destroy ."

label $MainWin.msg.lbl \
 -font $Font14 -text "HELP...MESSAGES...ERRORS" -bd 3 \
 -relief ridge -bg DarkSeaGreen
 
message $MainWin.msg.msg -relief sunken \
        -bg honeydew \
        -bd 2 \
        -fg maroon\
        -width 15c \
        -justify left \
        -font $Font14 \
        -text $HlpTxt
 
label $MainWin.msg.hst \
         -font $Font14 -text "COMMAND HISTORY" -bd 3 \
         -relief ridge -bg DarkSeaGreen
 
set cmdhistory $MainWin.msg.cmds
set cmdscroll $MainWin.msg.scroll
 
listbox $cmdhistory \
        -font $Font12 \
        -width 64 \
        -height 5 \
        -relief sunken \
        -bg honeydew \
        -yscrollcommand  "$cmdscroll set"
 
scrollbar $cmdscroll \
    -bg DarkSeaGreen \
    -command "$cmdhistory yview"

loop i 0 $maxcmd {
    $cmdhistory insert end ""
}
        
set MsgWin  $MainWin.msg.msg
pack $MainWin.msg.quit $MainWin.msg.lbl $MainWin.msg.msg  $MainWin.msg.hst \
     -side top -expand 1 -fill both
pack $cmdscroll -side right -fill y
pack $cmdhistory -fill both -expand 1 
pack $MainWin.ucp $MainWin.msg -side top -expand 1 -fill both

proc vipf { name } {
   
   global cmdhistory crnt_cmd

   set tmpstr [exec epoch now]
   set timestr [format "%s %s" [lindex $tmpstr 2] [lindex $tmpstr 3]]  

   $cmdhistory insert $crnt_cmd "$timestr\t vi $name"
   incr crnt_cmd 1
   exec xterm -bg honeydew -fg maroon -geom 80x40 -e vi $name & 
  
   dpadm pfclean 0
 
   return 
}