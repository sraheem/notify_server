Asterisk Notification Server for Canada Post
----------------------------------------------

This tool can be used in conjunction with Asterisk. Users receive phone calls when there's an update in their Canada post tracking information.

CANPOST_LIST format
-------------------

Each line should contain the following information for CanadaPost Tracking:

<CanadaPost PIN> <notify_level> <channelnumber1> [<channelnumber2> <channelnumber3> <channelnumber4> <channelnumber5>]

CanadaPost PIN: 13 - 16 digit alphanumeric tracking number from Canadapost

notify_level: NOT IMPLEMENTED. any number can be entered, and it will be ignored

channelnumber:

Minimum 1 channelnumber is needed. Maximum is 5. Seperated by spaces.

In the following format -

cccnnn.

Acceptable channels - IAX, MTF and SIP (MTF is preferred for North American Calls - Free!)
Number - Phone number/extension of the party to be called. Phone numbers should be in international format.


Features
--------
v1.9
*Externalizing sensitive variables, added gitignore

v1.8
*Invalid Response detection

Until v1.7 September 3, 2015:
* NADRA Compalint and Status sites check
   - Logging
   - Skips if site is down (complaint site only)

* CanadaPost Tracking Status changes
   - Logging
   - Parsing CANPOST_LIST file for info
   - Original file creator
   - Pacing for SLM compliance
   - Ignore and log SLM rejections
   - Tidy XML
   - PIN splititng for correct TTS pronounciation
   - notify_level variable declared

* Loop Control Variables
* Blackout time 1-6 am MST



Bugs & Upcoming features
------------------------

* Context sensitive notifications (CanadaPost)
* SMS Support
* Notify levels

