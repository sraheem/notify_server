#/bin/bash

#Purpose of this script is to create call file in /root/notify_server/callfiles/ using parameters channel, number,CallerID, retries and Recording Name.
#After file is generated, call file is 'safely' transferred to /var/spool/asterisk/outgoing/ directory.
#This script is intended to be called from other monitoring scripts which generate wish to generate calls. Reports to notify.log 
#Current functionality covers Playback and TTS function on outgoing Calls.
#Channels IAX2, SIP and Motif are supported. (v0.6)
#Flite has been commented out, and Google TTS is the default TTS 'engine' 
#Call file name format channelnumber_CID_App_time.call 

#Future bug fixes/enhancements
#Customizable recordings

#v0.7, August 23, 2015

channel=$1
number=$2
CID=$3
retries=$4
App=$5
data=$6

#echo "$channel $number $CID $retries $App $data"

if [ $# -ne 6 ]
then
    echo -e "\nUsage: This script requires exactly 6 variables to be passed.\n" 
    echo -e "./callfilegenerator.bash <channel> <number/extension> <CID> <retries> <Application> <data> \n"
    echo -e "\nApplication type can only be Playback or TTS.\n  - If Application is Playback, 6th parameter is inconsequential (NADRA file will be played).\n  - If Application is TTS, enter text to be spoken in double-quotes\n"
    exit
fi

#Application type validation
if [ "$App" = "Playback" ]
then
    RApp="Playback"
elif [ "$App" = "TTS" ]
then
    RApp="AGI"
else
    echo -e "\nApplication type can only be Playback or TTS.\n  - If Application is Playback, 6th parameter is inconsequential (NADRA file will be played).\n  - If Application is TTS. enter text to be spoken in double-quotes\n"
    exit
fi

#Channel name set/validation
if [ "$channel" = "IAX2" ] || [ "$channel" = "IAX" ] || [ "$channel" = "iax" ] || [ "$channel" = "iax2" ]
then
    channel="IAX2"
    channer="IAX2"
    GOOG=""
elif [ "$channel" = "SIP" ] || [ "$channel" = "sip" ]
then
    channel="SIP"
    channer="SIP/callwithus"
    GOOG=""
elif [ "$channel" = "MTF" ] || [ "$channel" = "mtf" ]
then
    channel="MTF"
    channer="Motif/gsyedraheem1986gmailcom"
    GOOG="@voice.google.com"
else
    echo -e "\nInvalid Channel.\n"
    exit
fi

#Setting shorted waittime to SIP calls to avoid spamming voicemails
if [ "channel" = "SIP" ] || [ "channel" = "MTF" ]
then
    waittime=30
else
    waittime=60
fi

#Setting Data field
if [ "$RApp" = "AGI" ]
then
    #newdata="propolys-tts.agi,\"$data\",flite,/usr/bin/flite"
    newdata="googletts-tiny.agi,\"$data\",en"
elif [ "$RApp" = "Playback" ]
then
    newdata="custom/NADRA_Change"
else
    exit
fi
    
filename="${channel}${number}_${CID}_${App}_`date +%Y%m%d%H%M%S`.call"

touch /root/notify_server/callfiles/$filename

echo -e "Channel: $channer/$number$GOOG" >> /root/notify_server/callfiles/$filename
echo -e "CallerID: $CID" >> /root/notify_server/callfiles/$filename
echo -e "MaxRetries: $retries" >> /root/notify_server/callfiles/$filename
echo -e "RetryTime: 3" >> /root/notify_server/callfiles/$filename
echo -e "WaitTime: $waittime" >> /root/notify_server/callfiles/$filename
echo -e "Application: $RApp" >> /root/notify_server/callfiles/$filename
echo -e "Data: $newdata" >> /root/notify_server/callfiles/$filename

echo "`date +%Y-%m-%dT%H:%M:%S` Attempting to Call $channel $number. Check CDR reports to see call status." >> /root/notify_server/notify.log

chown asterisk:asterisk /root/notify_server/callfiles/$filename

mv /root/notify_server/callfiles/$filename /var/spool/asterisk/outgoing/
