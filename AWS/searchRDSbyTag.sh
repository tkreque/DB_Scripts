#!/bin/bash

#################################################
#												#
#				AWS RDS search by Tag			#
#	Created by - Thiago Reque					#
#			Date: 			15/01/2018			#
#			Last changed:	07/05/2018			#
#												#
#	Change log:									#
#		- Created the script					#
#		- Adjust Search for multi-values		#
#												#
#################################################

# Get AWS Config file for default params
CONFIGFILE="$HOME/.aws/config"

# Ask the Tag value
echo "What is the TAG you're looking for?"
read TAGVALUE

# Ask the format or gets the default
echo "Output format (json, text, table)"
read OUTPUTFORMAT

case $OUTPUTFORMAT in
	"json")
		OUTPUT="json"
		;;
	"text")
		OUTPUT="text"
		;;
	"table")
		OUTPUT="table"
		;;
	*)
		echo "Invalid option! The default value will be setted!"
		while IFS='' read -r line || [[ -n "$line" ]]; do
		    if [[ "$line" == *"output"* ]]; then
			   	OUTPUT=$(cut -d "=" -f 2 <<< "$line" | sed 's/ //g')
			   	break
			fi
		done < "$CONFIGFILE"
		;;
esac	

# Ask the region or gets the default
echo "What region? (blank for default)"
read REGION

if [ ! $REGION ]; then
	while IFS='' read -r line || [[ -n "$line" ]]; do
	    if [[ "$line" == *"region"* ]]; then
		   	REGION=$(cut -d "=" -f 2 <<< "$line" | sed 's/ //g')
		   	break
		fi
	done < "$CONFIGFILE"
fi

# Ask the profile or gets the default
echo "Profile? (blank for default)"
read PROFILE

if [ ! $PROFILE ]; then
	PROFILE="default"
fi
echo ""

QUERYTEMP="aws rds describe-db-instances --query 'DBInstances[*].{InstanceName:DBInstanceIdentifier}' --output text --region $REGION --profile $PROFILE"
for RDS  in  $(eval "$QUERYTEMP"); do
    
    # Query temp to get the ARN for search the TAGS
	QUERYAUX="aws rds describe-db-instances --query 'DBInstances[?DBInstanceIdentifier==\`$RDS\`].{RN:DBInstanceArn}' --output text --region $REGION --profile $PROFILE"
	ARN=$(eval "$QUERYAUX")

	QUERYTAG="aws rds list-tags-for-resource --resource-name $ARN --output text --region $REGION --profile $PROFILE"
	TAG=$(eval "$QUERYTAG")
	
	TAG=${TAG^^}
	TAGVALUE=${TAGVALUE^^}
	
	if [[ "$TAG" == *"$TAGVALUE"* ]]; then
		echo ""
	    echo "======================================== INFOS : $RDS"
	    echo ""

	    # Query to list the RDS information
		QUERY01="aws rds describe-db-instances --query 'DBInstances[?DBInstanceIdentifier==\`$RDS\`].{
			InstanceName:DBInstanceIdentifier,
			Status:DBInstanceStatus,
			RdsEngine:Engine,
			RdsVersion:EngineVersion,
			MultiAZ:MultiAZ,
			AZ:AvailabilityZone,
			Storage:StorageType,
			Size:AllocatedStorage,
			OptionParamenter:OptionGroupMemberships[0].OptionGroupName,
			OptionParamenterStatus:OptionGroupMemberships[0].Status,
			DBParameter:DBParameterGroups[0].DBParameterGroupName,
			DBParamenterStatus:DBParameterGroups[0].ParameterApplyStatus,
			VpcID:DBSubnetGroup.VpcId,
			SubnetName:DBSubnetGroup.DBSubnetGroupName,
			RdsEndpoint:Endpoint.Address,
			RdsPort:Endpoint.Port,
			InstanceARN:DBInstanceArn,
			CreatedAt:InstanceCreateTime,
			CanBeRestoredUntil:LatestRestorableTime
		}' --output $OUTPUT --region $REGION --profile $PROFILE"
		eval "$QUERY01"
	
		# Query to get the TAGS for the RDS
		QUERY02="aws rds list-tags-for-resource --resource-name $ARN --output $OUTPUT --region $REGION --profile $PROFILE"
		eval "$QUERY02"
	fi
done
echo ""
echo "End of the search!"