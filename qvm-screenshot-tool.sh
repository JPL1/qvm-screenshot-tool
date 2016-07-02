#!/bin/sh

# Take screenshot in Qubes Dom0, auto copy to AppVM, upload to imgurl service
# Dependencies: scrot at dom0 (sudo qubes-dom0-update scrot) 
# zenity at dom0 and at AppVM (already exists by default at fedora and dom0)
#

# Plans: 1) delayed screenshots 
# 2) select multi regions and make one image from all of them to upload
# 3) upload any image from dom0 after select it
# 4) editor of screenshots before upload

version="0.1beta"
DOM0_SHOTS_DIR=$HOME/Pictures
APPVM_SHOTS_DIR=/home/user/Pictures
QUBES_DOM0_APPVMS=/var/lib/qubes/appvms/

UPLOADHELPER=$(cat <<'EOFFILE'
#!/bin/bash
# Eva Dog Star imgurl uploader

imgur_anon_id="ea6c0ef2987808e"

# check arguments
if [ $# == 0 ]; then
   echo "[ERROR] No file specified" >&2
   exit 16
fi

# check curl is available
type curl >/dev/null 2>/dev/null || {
   echo "[ERROR] Couln't find curl, which is required at AppVM." >&2
   exit 17
}

file="$1"
logfile="$2"   

   # check file exists
   if [ ! -f "$file" ]; then
      echo "[ERROR] file '$file' doesn't exist at AppVM" >&2
      exit 18
   fi

   response="$(curl --compressed --connect-timeout "5" -m "150" --retry "1" -fsSL --stderr - -H "Authorization: Client-ID ${imgur_anon_id}" -F "image=@$file" https://api.imgur.com/3/image)"

   if egrep -q '"success":\s*true' <<<"${response}"; then
       img_id="$(egrep -o '"id":\s*"[^"]+"' <<<"${response}" | cut -d "\"" -f 4)"
       img_ext="$(egrep -o '"link":\s*"[^"]+"' <<<"${response}" | cut -d "\"" -f 4 | rev | cut -d "." -f 1 | rev)" # "link" itself has ugly '\/' escaping and no https!
       del_id="$(egrep -o '"deletehash":\s*"[^"]+"' <<<"${response}" | cut -d "\"" -f 4)"

       imgurl="https://i.imgur.com/${img_id}.${img_ext}"
       imgdeleteurl="https://imgur.com/delete/${del_id}"

      echo -e "Image url:\n$imgurl\n\nDelete image url: \n$imgdeleteurl\n\n \nQubes Screenshot Tool - EvaDogStar 2016" > $logfile

      echo "[success] imgurl: $imgurl" >&2   
      echo "[success] delete url: $imgdeleteurl" >&2

   else # upload failed
       err_msg="$(egrep -o '"error":\s*"[^"]+"' <<<"${response}" | cut -d "\"" -f 4)"
       test -z "${err_msg}" && err_msg="${response}"
       echo "[ERROR] $err_msg"
       echo "[RESPONSE] $response" 

     echo -e "Error: \n\n$err_msg \n\nImgurl Server response: \n\n$response\n\n\n \nQubes Screenshot Tool - EvaDogStar 2016" > $logfile       
       #echo ${err_msg}
   fi

(which xclip &>/dev/null && echo -n "$imgurl" | xclip -selection clipboard ) || echo "[NOTE] no xclip at AppVM"
      

EOFFILE
)
#kdialog --msgbox "dsadasd"
#exit 1
#kdialog --inputbox "Url:" "fasffasf asfsaf af asf saf sdag sdg s"  "dasdas" "fgdsgsad"
#exit 1

# vai_ksnapshootxxx()
# {
#   # setGrabMode notes: 0=full-screen, 1=window, 2=region
#   #kstart -iconify ksnapshot && sleep 0.2
#   ksnapshot &
#   sleep 1
#   while [ "$PID" == "" ]; do PID="$(pgrep ksnapshot)"; done
#   program="org.kde.ksnapshot-${PID}"
# ####  qdbus $program /KSnapshot setGrabMode "$1"
# #####qdbus $program /KSnapshot setTime 0
# ####kdialog --radiolist "Continue upload process? Confirm only if you are ready" continue continue continue --default continue --title "$program" --nograb --noxim  

# zenity --question --text "Move this mindow away and make screenshot. When you will be ready to upload image click on OK button."

#   [[ $1 -eq 2 ]] && qdbus $program /KSnapshot slotGrab
#   [[ $1 -eq 4 ]] && qdbus $program /KSnapshot slotGrab  
#   [[ $1 -eq 2 ]] && sleep 4
#   #sleep 5
#   #kdialog --msgbox "click yes when you done ?"

#   # confirm dialog for region selection tool
# ###  [[ $1 -eq 2 ]] && kdialog --radiolist "Continue upload process? Confirm only if you are ready" continue continue continue --default continue --title "$program" --nograb --noxim
  
#   #qdbus $program /KSnapshot setURL "$2"
#   #qdbus $program /KSnapshot slotSave
# PID="$(pgrep -n ksnapshot)"
#    program="org.kde.ksnapshot-${PID}"
#   qdbus $program /KSnapshot slotGrab  
#   sleep 2

#   qdbus $program /KSnapshot save $2
#   echo "$2"
#   qdbus $program /KSnapshot exit
# }
checkscrot()
{  
   (which scrot &>/dev/null ) || { 
      scrotnomes="[EXIT] no \"scrot\" tool at dom0 installed use: \n\nsudo qubed-dom0-update scrot \n\ncommand to add it first"
      echo "$scrotnomes" 
      zenity --info --modal --text "$scrotnomes" &>/dev/null
      exit 1 
   }
}
# Should below be start_ksnapshot()?
start_ksnapshoot()
{
  PID="$(pgrep ksnapshot)"
  if [ "$PID" == "" ]; then
   ksnapshot &
   sleep 1
  fi
  # setGrabMode notes: 0=full-screen, 1=window, 2=region
  #kstart ksnapshot
  #kdialog --radiolist "Now you can user Snapshot tool to make screenshots. When and only when you will be ready with screenshot (check preview area) click OKEY. Confirm only if you are ready!" READY READY READY --default continue --title "$program" --nograb --noxim  
  zenity --question --text "Move this window away and make screenshot. When you are ready to upload image click OK."
  
  # while [ "$PID" == "" ]; do PID="$(pgrep -n ksnapshot)"; done

  # ksnap pid changed after using region selection tool
  PID="$(pgrep ksnapshot)"
  program="org.kde.ksnapshot-${PID}"
  qdbus $program /KSnapshot save $2
  echo "ksnap save: $2"
  qdbus $program /KSnapshot exit
}


 (which zenity &>/dev/null ) || { 
    scrotnomes="[FATAL] no \"zenity\" tool at dom0 installed use: \n\nsudo qubed-dom0-update zenity command to add it first"
    echo "$scrotnomes" 
    exit 1 
 }


program="`basename $0`"
shotslist=""

mkdir -p $DOM0_SHOTS_DIR ||exit 1
while true; do
   d=`date +"%Y-%m-%d-%H%M%S"`
   shotname=$d.png

   ans=$(zenity --list --modal --text "Choose capture mode \n Use:" --radiolist --column "Pick" --column "Option" \
   FALSE Ksnapshot \
   TRUE "Region or Window" \
   FALSE "Fullscreen" \
   ) 

#   echo $ans

  if [ X"$ans" == X"Ksnapshot" ]; then
   echo "[+] starting ksnapshot..."
   start_ksnapshoot 4 $DOM0_SHOTS_DIR/$shotname || break
  elif [ X"$ans" == X"Region or Window" ]; then
     checkscrot || break
     echo "[+] capturing window, click on it to select"
     scrot -s -b $DOM0_SHOTS_DIR/$shotname || break
  elif [ X"$ans" == X"Fullscreen" ]; then
     checkscrot || break
     echo "[+] capturing fullscreen desktop"      
     scrot -b $DOM0_SHOTS_DIR/$shotname || break
  else
     echo "You must select some mode to continue" && exit 1
  fi

  if [ -f "$DOM0_SHOTS_DIR/$shotname" ]
  then
      echo "[+] Success at dom0. Screenshot saved at $DOM0_SHOTS_DIR/$shotname" || break
  else
   echo "[ERROR] Something has gone wrong and screenshot has not been saved at dom0."
   $(zenity --info --modal --text "Something has gone wrong and screenshot has NOT been saved at dom0") 
   exit 12
  fi


   [[ $mode_quick -eq 1 ]] && exit 1
   shotslist="$shotname"
   #shotslist="${shotslist}${shotname}:"
   break

   # [[ $mode_multi -eq 1 ]] && kdialog --yesno "Other shot ?" || break
done


  
 ans=$(zenity --list --modal --width=200 --height=290 --text "Screenshot saved at dom0 \nWhat do you want to do next?\nSelect or multiselect some options:" --checklist --column "Pick" --column "Options" \
   FALSE Exit \
   FALSE "Upload to AppVM only" \
   FALSE "Upload to Imgurl" \
   FALSE "Start Nautilus at AppVM" \
   FALSE "Keep screenshot at dom0"
   ) 
   #echo "xxx $ans xxx"

[[ X"$ans" == X"" ]] && exit 1

mode_onlyupload=0
mode_nautilus=0
mode_imgurl=0
mode_not_delete_screen_at_dom=0

IFSDEFAULT=$IFS
IFS='|'; for val in $ans; 
do 
#echo "variable: $val and $1"
case $val in
  'Exit') echo "[+] Good Bye"; exit 1 ;;
  'Upload to AppVM only') mode_onlyupload=1;  ;;
  'Upload to Imgurl') mode_imgurl=1;  ;;
  'Start Nautilus at AppVM') mode_nautilus=1;  ;;
  'Keep screenshot at dom0') mode_not_delete_screen_at_dom=1;  ;;
 # -r) mode_region=1;  ;;
  *) echo "Never Good Bye!"; exit 1 ;;
esac done

IFS=$IFSDEFAULT
choiceappvm=`ls $QUBES_DOM0_APPVMS |sed 's/\([^ ]*\)/FALSE \1 /g'`
#appvm=`kdialog --radiolist "Select destination AppVM" $choice --title "$program"`
appvm=$(zenity --list --modal  --width=200 --height=390  --text "Select destination AppVM (unix based):" --radiolist --column "Pick" --column "AppVM" $choiceappvm ) 
#echo $appvm


if [ X"$appvm" != X"" ]; then

   echo "[-] start AppVM: $appvm"
   qvm-run -a $appvm "mkdir -p $APPVM_SHOTS_DIR"

   if [ $mode_nautilus -eq 1 ]; then
      echo "[-] running nautilus in AppVM"
      qvm-run $appvm "nautilus $APPVM_SHOTS_DIR"
      sleep 1
   fi

   shot=$shotslist

   echo "[-] copying screenshot to $APPVM_SHOTS_DIR/$shot"
   cat $DOM0_SHOTS_DIR/$shot \
      |qvm-run --pass-io $appvm "cat > $APPVM_SHOTS_DIR/$shot"

   [[ $mode_not_delete_screen_at_dom -eq 1 ]] && rm -f $DOM0_SHOTS_DIR/$shot && echo "[+] Screen at dom0 deleted $DOM0_SHOTS_DIR/$shot"
   [[ $mode_onlyupload -eq 1 ]] && exit 1


   [[ $mode_imgurl -eq 0 ]] && exit 1

   echo "[-] copying imgurl uploader to AppVM $appvm"
#      echo $UPLOADHELPER \
#          | qvm-run --pass-io $appvm "echo $UPLOADHELPER > $APPVM_SHOTS_DIR/autouplodertemp.sh"
   uploadername='evauploadermgur.sh'
   logfile="$APPVM_SHOTS_DIR/imgurl.log"
   echo "$UPLOADHELPER" | qvm-run --pass-io $appvm "cat > $APPVM_SHOTS_DIR/$uploadername"
   qvm-run --pass-io $appvm "chmod +x $APPVM_SHOTS_DIR/$uploadername"
   RESULT="$(qvm-run --pass-io $appvm "$APPVM_SHOTS_DIR/$uploadername $APPVM_SHOTS_DIR/$shot $logfile")"
   qvm-run $appvm "rm $APPVM_SHOTS_DIR/$uploadername"
   #qvm-run $appvm "gedit $logfile" 
   qvm-run $appvm "zenity --text-info --width=500 --height=180 --modal --filename=$logfile --text Ready" 
   echo $RESULT

   #done
else
   echo "[-] no AppVM name provided"
fi

echo "[*] Dom0 say Good Bye"

