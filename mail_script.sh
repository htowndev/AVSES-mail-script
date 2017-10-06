#!/bin/bash
MESSAGE=$(/usr/sbin/exiqgrep -i)
SPOOLDIR=/var/spool/sa-exim/SAnotspam/
DIR=/home/ottoman/Documents


#clear;

##Roomba function Searches Exim queue for message Id and places into an array message_id
roomba()
        {
        message_id=()
        while read -r line; do
        message_id+=("$(/usr/sbin/exim -Mvb $line| grep -i 'Message-Id: <' | cut -d ':' -f2 | tr -d \<\>' ')")
        done < <(/usr/sbin/exiqgrep -i)

##Reads through message-id array and places filename in file() array
       files=()
       while  read -r line; do
       files+=("$(find $SPOOLDIR -maxdepth 2 -mtime -4 | grep  $line)")
       done < <(printf '%s\n' "${message_id[@]}")
       printf '%s\n' "${files[@]}"
}

##Function scores SPAM for each bounceback -- reads through filename array and scores each email file with spamassassin engine
sarge()
	{
	scores=()
	while read -r line; do 
	scores+=("$(spamassassin -Lt $line| tail -10)")
	done < <(printf '%s\n' "${files[@]}")
	printf '%s\n' "${scores[@]}"
}

##This function is for option 2. It searches the SAspamaccept pool for false positive
##I'll have to add a regex for verifying input is valid email address
##What is EMAIL=$1  double check this
retrieve()
	{
	EMAIL=$1
	read  -p $'Please enter the email address or domain name of the sender for missing email:\n' address
	printf '%s\n' "Searching SPAM spool for missing email..."
	emails=($(grep -R $address /var/spool/sa-exim/SAspamaccept | awk -F : '{print $1}' |uniq)) 

#loops through email array and prints with index
	for ((i = -1; i < ${#emails[@]}; ++i)); do
	  position=$(( $i + 1 ))
	 echo "$position)${emails[$i]}"
done
##Invoking baseorhtml function
	baseorhtml
	#printf '%s\n''%s\n' "Your search yielded the following:" "${emails[@]}"
}


##This function tests whether the email message is base64 encoded or HTML
##IT does so by searching for 'base64' string
baseorhtml()	
	{
	read -p $'Which would you like to view? Please enter a number:\n' choice
##This is comparing choice vs  filename and not array index	
set -x
	for ((i = 0 ; i < ${#emails[@]}; ++i)); do
	   if [ "$choice" == ${i} ];then
	    #echo "${emails[$choice]}"
	    FORMAT=$(grep -m 1 -o "base64" ${emails[choice]})
		if [ $format = " " ];then
		$("${emails[$choice]}" | awk 'NextPart/{p=1}p{print}/NextPart/{p=1}')
		else
		$("${emails[$choice]}" | sed -n '/base64/,${p;/boundary/q;}' | tail -n +1 | head -n -1)
		fi
	    else 
		echo "Wrong choice"
	   fi
done
}




#Options Menu
	while true; do
	clear
	cat<<EOF
	
	======================================
		SPAM Script v1.4
	======================================
	(1) Find bouneback files stuck in queue
	(2) Find email that was rejeceted or flagged as SPAM
	(3) Check SPAM rules/scores for bouncebacks stuck in queue 
	(4) Check Exim queue
	(5) Quit
	
EOF
	
	read -n1 -s -p $'Please make your selection:\n' response
	clear
	case $response in 
	1) printf '%s\n' "Searching for bounceback files...";roomba;;
	2) retrieve ;;
	3) sarge;;
	4) /usr/sbin/exim -bp;;
	5) echo 'Goodbye';break;;
	*) echo"Invalid option";;
	

        esac
	read -p "Press enter to continue"
done	


	


