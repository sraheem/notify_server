#!/bin/bash

#Hourly checks on websites/webservices URL's using curl command to check status. Add more lines as needed. Logging in notify.log .
#NADRA Complaint site, NADRA Status, CanadaPost supported.
#See README for more details
#Add tracking numbers to CANPOST_LIST.txt for tracking Canada Post parcels
#v 1.8, September 21, 2015

#Loop variable declaration
NCLoop=1
NSLoop=1
#CPLoop=1

#NADRA complaint check
while [ $NCLoop -eq 1 ] 
do
curl -s https://nadra.gov.pk/chat/complaint/ticket.php?track=H7QBJZ7SNN | grep -v change_status.php > /root/notify_server/texts/NADRA_complain_temp.txt

#Check if website down. Log and Ignore
NCdown=$( grep -c "We are sorry for the inconvenience" /root/notify_server/texts/NADRA_complain_temp.txt)
#echo $NCdown
if [ $NCdown -ne 0 ]
then
    echo "`date +%Y-%m-%dT%H:%M:%S` NADRA Complain website down, check manually if problem persists" >> /root/notify_server/notify.log
    break
fi

#NADRA complaint Comparison alogorithm
if diff /root/notify_server/texts/NADRA_complain_orig.txt /root/notify_server/texts/NADRA_complain_temp.txt >> /dev/null
then
    echo "`date +%Y-%m-%dT%H:%M:%S` No difference in NADRA Complaint" >> /root/notify_server/notify.log
    #Log and do nothing
else
    echo "`date +%Y-%m-%dT%H:%M:%S` Difference found - NADRA Complaint." >> /root/notify_server/notify.log
    #After logging make calls
    sleep 1
    /root/notify_server/callfilegenerator.bash MTF 15879693460 NADRA_Complaint 3 Playback NADRA
    sleep 240
#    /root/notify_server/callfilegenerator.bash IAX 101 NADRA_Complaint 3 Playback NADRA
#    sleep 240
#    /root/notify_server/callfilegenerator.bash IAX 102 NADRA_Complaint 3 Playback NADRA
#    sleep 240
#    /root/notify_server/callfilegenerator.bash IAX 123 NADRA_Complaint 3 Playback NADRA
#    sleep 2
    echo "`date +%Y-%m-%dT%H:%M:%S` Updating NADRA original." >> /root/notify_server/notify.log
    mv -f /root/notify_server/texts/NADRA_complain_temp.txt /root/notify_server/texts/NADRA_complain_orig.txt
fi
NCLoop=$((NCLoop + 1))
done


#NADRA status check
while [ $NSLoop -eq 1 ]
do
curl -s -d "frno=2168999&&type=nicop" https://www.nadra.gov.pk/nicoppoctracking/status.php > /root/notify_server/texts/NADRA_status_tmp.txt

#NADRA Status Comparison alogorithm
if diff /root/notify_server/texts/NADRA_status_orig.txt /root/notify_server/texts/NADRA_status_tmp.txt >> /dev/null
then
    echo "`date +%Y-%m-%dT%H:%M:%S` No difference in NADRA Status (2168999)." >> /root/notify_server/notify.log
    #Log and do nothing
else
    echo "`date +%Y-%m-%dT%H:%M:%S` Difference found - NADRA Status (2168999)." >> /root/notify_server/notify.log
    #After logging make calls
    sleep 1
    /root/notify_server/callfilegenerator.bash IAX 101 NADRA_Status 3 TTS "NADRA Status has been updated. Please check NICOP status for 2 1 6 8 9 9 9"
    sleep 240
    /root/notify_server/callfilegenerator.bash MTF 15879693460 NADRA_Status 3 TTS "NADRA Status has been updated. Please check NICOP status for 2 1 6 8 9 9 9"
    #sleep 240
    #/root/notify_server/callfilegenerator.bash IAX 123 NADRA_Status 3 TTS "NADRA Status has been updated. Please check NICOP status for 2 1 6 8 9 9 9"
    sleep 1
    echo "`date +%Y-%m-%dT%H:%M:%S` Updating NADRA status original." >> /root/notify_server/notify.log
    mv -f /root/notify_server/texts/NADRA_status_tmp.txt /root/notify_server/texts/NADRA_status_orig.txt
fi
NSLoop=$((NSLoop + 1))
done


# CanadaPost Loop

#Parameter check and function definition
#Substitute with your Canadapost Developer Credentials.
cancheck ()
{
curl -s --cacert /root/notify_server/cert/cacert.pem -X GET -u "c65828b0742b48f3:6f20cb918dd596f5bcb1ae" -H "Accept:application/vnd.cpc.track+xml" -H "Accept-Language:en-CA" https://soa-gw.canadapost.ca/vis/track/pin/$PIN/detail | tidy -xml -iq
}


#Loop start
while read line; do
    sleep 4
    IFS=' ' read -a callarray <<< "$line"

    PIN=${callarray[0]}
    notify_level=${callarray[1]}
    numstring1=${callarray[2]}
    numstring2=${callarray[3]}
    numstring3=${callarray[4]}
    numstring4=${callarray[5]}
    numstring5=${callarray[6]}

    #splitting PIN by spaces for effective TTS reading
    splitPIN=$( echo $PIN | awk NF=NF FS= )
    #echo $splitPIN


    orig_file="${PIN}_orig.txt"
    temp_file="${PIN}_temp.txt"

    chan1=$( echo $numstring1 | cut -c1-3 )
    num1=$( echo $numstring1 | cut -c4- )
    chan2=$( echo $numstring2 | cut -c1-3 )
    num2=$( echo $numstring2 | cut -c4- )
    chan3=$( echo $numstring3 | cut -c1-3 )
    num3=$( echo $numstring3 | cut -c4- )
    chan4=$( echo $numstring4 | cut -c1-3 )
    num4=$( echo $numstring4 | cut -c4- )
    chan5=$( echo $numstring5 | cut -c1-3 )
    num5=$( echo $numstring5 | cut -c4- )


    #Check if original file existed.
    if [ ! -f /root/notify_server/texts/$orig_file ]
    then
        echo "`date +%Y-%m-%dT%H:%M:%S` New tracking number found in CANPOST_LIST.txt. Creating original." >> /root/notify_server/notify.log
        cancheck > /root/notify_server/texts/$orig_file
        sleep 4
    fi

    #Check current status
    cancheck > /root/notify_server/texts/$temp_file

    #Break from loop if SLM/backend/Auth failure is received
    isSLM=$( grep -c "Rejected by SLM Monitor" /root/notify_server/texts/$temp_file )
    isBCK=$( grep -c "Failed to establish a backside" /root/notify_server/texts/$temp_file )
    isAAA=$( grep -c "AAA Authentication Failure" /root/notify_server/texts/$temp_file )

    if [ $isSLM -ne 0 ]
    then
        echo "`date +%Y-%m-%dT%H:%M:%S` SLM Monitor rejected tracking of $PIN. Please check if problem persists." >> /root/notify_server/notify.log
        continue
    elif [ $isBCK -ne 0 ]
    then
        echo "`date +%Y-%m-%dT%H:%M:%S` Failed to establish backend connection while tracking $PIN. Please check if problem persists." >> /root/notify_server/notify.log
        continue
    elif [ $isAAA -ne 0 ]
    then
        echo "`date +%Y-%m-%dT%H:%M:%S` One-off AAA Auth failure detected while tracking $PIN. Please check if problem persists." >> /root/notify_server/notify.log
        continue
    fi

    #Comparison Alogorithm
    if diff /root/notify_server/texts/$orig_file /root/notify_server/texts/$temp_file >> /dev/null
    then
        echo "`date +%Y-%m-%dT%H:%M:%S` No difference in CanadaPost Tracking $PIN." >> /root/notify_server/notify.log
        #Log and do nothing
    else
        echo "`date +%Y-%m-%dT%H:%M:%S` Difference found - CanadaPost $PIN." >> /root/notify_server/notify.log
	mv -f /root/notify_server/texts/$temp_file /root/notify_server/texts/$orig_file
        #After logging, make calls, ensure chan/num exist before each call
        if [ ! -z "$chan1" ]
        then
        /root/notify_server/callfilegenerator.bash $chan1 $num1 Notify_CanadaPost 3 TTS "There is an update in Canada Post tracking of $splitPIN. Thanks. Goodbye!"
	sleep 240
        fi

        if [ ! -z "$chan2" ]
        then
        /root/notify_server/callfilegenerator.bash $chan2 $num2 Notify_CanadaPost 3 TTS "There is an update in Canada Post tracking of $splitPIN. Thanks. Goodbye!"
	sleep 240
        fi

        if [ ! -z "$chan3" ]
        then
        /root/notify_server/callfilegenerator.bash $chan3 $num3 Notify_CanadaPost 3 TTS "There is an update in Canada Post tracking of $splitPIN. Thanks. Goodbye!"
	sleep 240
        fi

        if [ ! -z "$chan4" ]
        then
        /root/notify_server/callfilegenerator.bash $chan4 $num4 Notify_CanadaPost 3 TTS "There is an update in Canada Post tracking of $splitPIN. Thanks. Goodbye!"
	sleep 240
        fi

        if [ ! -z "$chan5" ]
        then
        /root/notify_server/callfilegenerator.bash $chan5 $num5 Notify_CanadaPost 3 TTS "There is an update in Canada Post tracking of $splitPIN. Thanks. Goodbye!"
	sleep 240
        fi
    fi
done < /root/notify_server/CANPOST_LIST.txt
