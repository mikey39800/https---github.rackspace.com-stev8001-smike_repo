#!/bin/bash

yellow=`tput setaf 3`
green=`tput setaf 2`
red=` tput setaf 1`
reset=`tput sgr0`

#checking for input after script call
if [ -z "$1" ];
then
    echo "${red}Tool usage example: phperrors.sh website.com${reset}"
    exit 0
fi

if [ -f ./"$1"_php_errors.log ];
then
    echo "${red}$1_php_errors.log already exists in this directory. Please remove it first.${reset}"
    exit 0
fi

if [ -f ./deletable.tmp ];
then
    echo "${red}deletable.tmp already exists in this directory. Please remove it first.${reset}"
    exit 0
fi

#based around path, copies the log to your directory
sitepath=$(path "$1" | grep nfs | awk '{print $3}')
sudo cat $sitepath/logs/php_errors.log > ./"$1"_php_errors.log

#is copied log empty?
if [ -s ./"$1"_php_errors.log ];
then
    clear
    echo "${green}***** I copied the php_errors.log to this directory *****"
    echo "***** and named it $1_php_errors.log *****"
    echo "***** Excluding timestamps, the unique entries are: *****${reset}"
    echo

#removes timestamps from log, sorts, creates a temp file used for actual reading
    awk '{$3=""; $2=""; $1=""; print}' ./"$1"_php_errors.log | sort | uniq > ./deletable.tmp
    while read line
    do
        echo "$line"

#series of greps, keywords determine dynamic comments
#counts for instances of keyword and stops at the first; if true, continues

        value=$(grep -cl "memory size" <<< $line)
        if [[ $value ]]
        then megabytes=$( echo "$line" | grep -o -P -m 1 '.{0,9}bytes' | head -1)
            megabytes=${megabytes%% bytes*}                                 #grabs byte count and removes the word 'bytes'
            echo "${yellow}Needs more than $(($megabytes/1048576))MB. Try 'php_value memory_limit ?M' in .htaccess${reset}"
        fi

        value=$(grep -cl "Uncaught exception" <<< $line)
        if [[ $value ]]
        then echo "${yellow}An exception handler should be created to 'try' the exception and specify the result of catching.${reset}"
        fi

        value=$(grep -cl "PHP Deprecated:" <<< $line)
        if [[ $value ]]
        then echo "${yellow}This code will cause errors vs warnings in the future. Customer should replace when possible.${reset}"
        fi

        value=$(grep -cl "redeclare" <<< $line)
        if [[ $value ]]
        then echo "${yellow}Did they include a file twice? This resource could be listed again through an include.${reset}"
        fi

        value=$(grep -cl "for inclusion" <<< $line)
        if [[ $value ]]
        then echo "${yellow}Was the declared file moved or missing? Include paths may be wrong in the script.${reset}"
        fi

        value=$(grep -cl "undefined function" <<< $line)
        if [[ $value ]]
        then echo "${yellow}Did they forget to upload a file? Our environment does not provide this function.${reset}"
        fi

        value=$(grep -cl "Strict Standards:" <<< $line)
        if [[ $value ]]
        then echo "${yellow}Adhering to these ensures code won't be deprecated. Not necessarily an error; consider disabling.${reset}"
        fi

        value=$(grep -cl "Permission denied" <<< $line)
        if [[ $value ]]
        then echo "${yellow}The app runs as the primary. Is it creating to a location that lacks permissions?${reset}"
        fi

        value=$(grep -cl "No such file" <<< $line)
        if [[ $value ]]
        then echo "${yellow}Was the declared file moved or missing? Include paths may be wrong in the script.${reset}"
        fi

        value=$(grep -cl "syntax error, unexpected" <<< $line)
        if [[ $value ]]
        then echo "${yellow}Too few or too many characters in a script. A text editor might have input extras.${reset}"
        fi

        value=$(grep -cl "Missing argument" <<< $line)
        if [[ $value ]]
        then echo "${yellow}The developer might try adding a default value if arguments aren't being passed properly.${reset}"
        fi

        value=$(grep -cl "not connect to SMTP" <<< $line)
        if [[ $value ]]
        then echo "${yellow}There may be a problem with the mailbox name, password, port, or server listed.${reset}"
        fi

        value=$(grep -cl "to be resource, boolean given" <<< $line)
        if [[ $value ]]
        then echo "${yellow}Developer can run the query in PHPMyAdmin to see why the server returned 'False'.${reset}"
        fi

        value=$(grep -cl "session had already" <<< $line)
        if [[ $value ]]
        then echo "${yellow}The session_start() function is being called twice in the same script or in an include.${reset}"
        fi

        value=$(grep -cl "undefined constant name" <<< $line)
        if [[ $value ]]
        then echo "${yellow}Script used a variable without the $ character or didn't define a constant until that line.${reset}"
        fi

        value=$(grep -cl "Cannot modify header information" <<< $line)
        if [[ $value ]]
        then echo "${yellow}There could be white spaces or code prior to <?php. Compromise scan is a good idea.${reset}"
        fi

        value=$(grep -cl "undefined variable" <<< $line)
        if [[ $value ]]
        then echo "${yellow}A variable wasn't defined before this line. Can use isset() to see if exists.${reset}"
        fi

        value=$(grep -cl "undefined index" <<< $line)
        if [[ $value ]]
        then echo "${yellow}Developer can create the index to access only defined elements. Can use isset() to see if they exist.${reset}"
        fi

        value=$(grep -cl "Illegal offset type" <<< $line)
        if [[ $value ]]
        then echo "${yellow}A function, array, object, or bad value might be used as index of an array element.${reset}"
        fi

        value=$(grep -cl "to be resource, integer" <<< $line)
        if [[ $value ]]
        then echo "${yellow}A file likely failed to open and an error code was given instead. Try full path for file reference.${reset}"
        fi

        value=$(grep -cl "preg_match(): Compilation failed" <<< $line)
        if [[ $value ]]
        then echo "${yellow}That function may have been used with an incorrect regular expression pattern. Check the syntax.${reset}"
        fi

        value=$(grep -cl "to be string; array" <<< $line)
        if [[ $value ]]
        then echo "${yellow}A function was given an array instead of a string. Avoid mult-dimensional arrays in some cases.${reset}"
        fi

        value=$(grep -cl "to be array; string" <<< $line)
        if [[ $value ]]
        then echo "${yellow}Developer can check if argument given is an array with the is_array() function.${reset}"
        fi

        value=$(grep -cl "Unexpected end tag" <<< $line)
        if [[ $value ]]
        then echo "${yellow}Invalid HTML could be being passed to the loadHTML() method.${reset}"
        fi

        value=$(grep -cl "not proper UTF-8" <<< $line)
        if [[ $value ]]
        then echo "${yellow}The utf8_encode() function can be used to properly convert the intended string.${reset}"
        fi

        value=$(grep -cl "preg_match Unknown modifier" <<< $line)
        if [[ $value ]]
        then echo "${yellow}This occurs when delimiters are not added for regular expression patterns. /, @, and # are popular.${reset}"
        fi

        value=$(grep -cl "argument supplied for foreach()" <<< $line)
        if [[ $value ]]
        then echo "${yellow}Use is_array() function to check if array is the variable being traversed by foreach().${reset}"
        fi

        value=$(grep -cl "function bind_param() on boolean" <<< $line)
        if [[ $value ]]
        then echo "${yellow}There is likely an issue with the SQL query. Have the customer try to get a SQL error.${reset}"
        fi

        value=$(grep -cl "Undefined property" <<< $line)
        if [[ $value ]]
        then echo "${yellow}The property_exists() function may help troubleshoot the problem.${reset}"
        fi

        echo
    done < ./deletable.tmp

    rm ./deletable.tmp
    echo "${red}End of Script${reset}"
    exit 0

#if copied log is empty, removes it and quits
else
    rm ./"$1"_php_errors.log
    echo "${red}Tool usage example: phperrors.sh website.com"
    echo "There may be no php errors on this site, logging could be suppressed, or the logging is relocated by code.${reset}"
    echo
fi
