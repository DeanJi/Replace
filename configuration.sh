#!/bin/bash

##############################
#Validation for parameter file
##############################

echo "Please select environment value:"
CONF_OPTIONS="DEV SIT"
select opt in $CONF_OPTIONS; do
        if [ "$opt" = "DEV" ]; then                
			ParamFile=filter-$opt.properties
			echo $ParamFile
			break
        elif [ "$opt" = "SIT" ]; then
        	ParamFile=filter-$opt.properties
			echo $ParamFile
			break
        else
            echo "Unknown Option"
        fi
done

chmod -fR 774 /tmp/testing

DESTDIR=/tmp/testing

if [ ! -f $ParamFile ] ; then
	echo
	echo "Error: Unable to find parameter file $ParamFile"
	exit -1
fi
param_count=`grep -v '^[ \t]*#' $ParamFile |wc -l`
echo "$param_count Parameters found in $ParamFile"
echo "Creatong a temporary file with the parameter list"
touch $ParamFile.tmp 
if [ $? != 0 ] ; then
    echo "Unable to crate the temporary file ...Exiting"
    exit
fi
grep -v '^[ \t]*#' $ParamFile > $ParamFile.tmp2 
grep -v '^$' $ParamFile.tmp2 > $ParamFile.tmp
rm $ParamFile.tmp2

while read LINE
do
    param_name=`echo  $LINE | cut -d'=' -f1`
    param_value=`echo  $LINE | cut -d'=' -f2`
    if [ -z $param_value ]; then
       echo "Value not defined properly for $param_name ....Exiting" 
       exit
    fi
done < $ParamFile.tmp
echo "Validation of param file Completed"


cat $ParamFile.tmp  | sed 's/\\/\\\\\\\\/g' | sed 's/\//\\\\\//g' | sed 's/\*/\\\\\*/g' | sed 's/"/\"/g' | sed 's/\"/\\\\\"/g' | sed 's/\@/\\\\\@/g' > $ParamFile.tmp1 
mv $ParamFile.tmp1 $ParamFile.tmp

FileName=$ParamFile.tmp

while read LINE
do

    param_name=`echo $LINE | cut -d'=' -f1`
    param_value=`echo  $LINE | cut -d'=' -f2`
    echo "param_name=$param_name"
    echo "param_value=$param_value"
 
    l=\\$\\$

    echo "Scanning for the variable $param_name... "
    for input_file in `find $DESTDIR -type f `
    do
       
	param_count=`grep "$l$param_name$l" $input_file|wc -l` 
	
         if [ $param_count -gt 0 ]; then

            perl -p -i -e "s/$l$param_name$l/$param_value/g" $input_file
            if [ $? != 0 ]; then
                 echo "Unable to replace the parameter in $input_file ...Exiting"
                 exit
            fi  

            echo "$input_file updated"
           
         fi
    done
done < $FileName

rm $FileName

echo "Parameter replacement completed"

