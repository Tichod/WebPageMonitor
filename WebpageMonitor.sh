#!/bin/bash
# WebPageMonitor.sh
# by Tichod <https://github.com/Tichod>
# Created   : <13/12/2012 11:14:51 Tichod>
# Last modif: <09/11/2022 17:11:12 Tichod>

# ================== Licence                   BEGIN ==================
           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                   Version 2, December 2004

Copyright (C) 2021 Tichod <https://github.com/Tichod>

Everyone is permitted to copy and distribute verbatim or modified
copies of this license document, and changing it is allowed as long
as the name is changed.

           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

 0. You just DO WHAT THE FUCK YOU WANT TO.
# ================== Licence                    END   ==================

# Ran by: crontab
## Web Page Monitoring
#56 * * * *  /bin/bash ~/bin/WebPageMonitor.sh

# Description : WebPageMonitor.sh checks if web pages have been modified and sends a notification by email if so

# ================== Variables definition      BEGIN ==================
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin
RootDir=~/veille/
SourceServer=$(hostname --fqdn)
export URLList=${RootDir}/url_list
# File format:
# National Cybersecurity Center of Excellence - News;https://www.nccoe.nist.gov/news;NCCOE-News;xxx.xxxx@example.org;theme_token\|form_build_id\|view-dom-id\|views-field
# \________________________________________________/ \_____________________________/ \________/ \__________________/ \____________________________________________________/
#                     \                                           \                       \               \                              \
#                      \                                           \                       \               \                              \-> cf. [1] hereunder
#                       \                                           \                       \               \-> recipient email address
#                        \                                           \                       \-> storage directory (under ${RootDir})
#                         \                                           \-> site URl
#                          \-> title (present in subject of the notification email)
# Notes :
# [1] Some pages contain frequently changing code, which does not affect the visible content of the page.
#     In order to disregard such changes, lines containing these character strings are excluded from the comparison.
#
#     /!\ chain separator =  << \| >>
#     /!\ no space in character strings
#     /!\ test before go-live
DefaultEscapedString='generated|served|expires|<!--|-->|batcache|html|meta|googleanalytics|twitter|nonce'
# ================== Variables definition       END  ==================

# ================== Functions definition      BEGIN ==================
function Signature()
{
    echo "Message sent by script $0 from server $SourceServer"
} # End of function Signature()
# ================== Functions definition       END  ==================

if [[ -f $URLList ]]
then
  while read Ligne
  do
      if [[ (! "$Ligne" =~ ^#.*) && (! "$Ligne" =~ ^$) ]]
      then
        Title=$(echo $Ligne | gawk -F ";" '{print $1}')
        RenamedTitle=$(echo $Title | sed -e 's/ /_/g')
        URL=$(echo $Ligne | gawk -F ";" '{print $2}')
        Dir=${RootDir}$(echo $Ligne | gawk -F ";" '{print $3}')/
        Recipient=$(echo $Line | gawk -F ";" '{print $4}')
        EscapedString=$(echo $Line | gawk -F ";" '{print $4}')
        MessageBody=${Dir}message
        if [[ ! -e $Dir ]]
        then
          mkdir $Dir
        fi # End of : if [[ ! -e $Dir ]]

        mv -f ${Dir}$RenamedTitle ${Dir}${RenamedTitle}.previous
        wget -q --no-check-certificate $URL -O ${Dir}$RenamedTitle

        # Suppression of lines containing frequently changing strings without affecting the visible content of the page
        if [[ X"$EscapedString" == "X" ]]
        then
          grep -viE "$DefaultEscapedString" ${Dir}$RenamedTitle > "$0.tmp" && mv -f "$0.tmp" ${Dir}$RenamedTitle
        else
            grep -viE "$DefaultEscapedString|$EscapedString" ${Dir}$RenamedTitle > "$0.tmp" && mv -f "$0.tmp" ${Dir}$RenamedTitle
        fi # End of : if [[ X"$EscapedString" == "X" ]]
        diff -q ${Dir}${RenamedTitle}.previous ${Dir}$RenamedTitle >>/dev/null 2>&1
        DiffResult="$?"

        if [[ "$DiffResult" -eq 0 ]]
        then
          true
          # Possibility: send an email regularly to check if script running correctly (false negative)
        else
            Subject="WebPageMonitor - New information published by $Title"
            echo "URL : $URL" > $MessageBody
            echo "Difference :" >> $MessageBody
            diff  ${Dir}${RenamedTitle}.previous ${Dir}$RenamedTitle >> $MessageBody
            echo "================" >> $MessageBody
            Signature >> $MessageBody
            cat $MessageBody | mail -s "$Subject" "$Recipient"
        fi # End of : if [[ "$DiffResult" -eq 0 ]]
      else
          # Commented out text or empty line
          true
      fi # End of : if [[ ! "$Line" =~ "^#" ]]
  done  < $URLList # End of : while read Line
else
    echo "Can't find configuration file $URLList, create it" | mail -s "Incident $0" $Recipient
    exit 1
fi # End of : [[ -f $URLList ]]

exit 0

#### Local Variables: ####
#### time-stamp-start:"Last modif: <" ####
#### time-stamp-end:">" ####
#### time-stamp-format:"%02d/%02m/%04y %02H:%02M:%02S Tichod" ####
#### End: ####
