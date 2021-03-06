#!/usr/bin/env bash
#Script for Legion clusters orchestration

set -e

function ReadArguments() {
	export VERBOSE=false
	export TF_SUPPORTED_COMMANDS=(create destroy)

	if [[ $# == 0 ]]; then
		echo "ERROR: Options not specified! Use -h for help!"
		exit 1
	fi

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help)
				echo "tf_runner.sh - Run Terraform modules for Legion clusters orchestration."
				echo "Usage: ./tf_runner.sh [OPTIONS]"
				echo " "
				echo "options:"
				echo -e "[create|destroy]\tcommand to execute: ${TF_SUPPORTED_COMMANDS[@]}"
				echo -e "-v  --verbose\t\tverbose mode for debug purposes"
				echo -e "-h  --help\t\tshow brief help"
				exit 0
				;;
			create)
				export COMMAND="create"
				shift
				;;
			destroy)
				shift
				export COMMAND="destroy"
				;;
			-v|--verbose)
				export VERBOSE=true
				shift
				;;
			*)
				echo "ERROR: Unknown option: $1. Use -h for help."
				exit 1
				;;
		esac
	done

	# Check mandatory parameters
	if [[ ! $COMMAND ]]; then
		echo "ERROR: Command argument must be specified. Use -h for help!"
		exit 1
	fi
	# Validate profile path
	if [[ ! $PROFILE ]]; then
		echo "ERROR: No PROFILE found. Pass path to the Cluster profile json file as PROFILE env var!"
		exit 1
	fi
	# Validate Command parameter
	if [[ ! " ${TF_SUPPORTED_COMMANDS[@]} " =~ " ${COMMAND} " ]]; then
		echo "ERROR: incorrect Command parameter \"$COMMAND\", must be one of ${TF_SUPPORTED_COMMANDS[@]}!"
		exit 1
	fi
	if [[ $VERBOSE == true ]]; then
		set -x
	fi
}

# Get parameter from cluster profile
function GetParam() {
	result=$(jq -r ".$1" $PROFILE)
	if [[ $result == null ]]; then
		echo "ERROR: $1 parameter is missing in $PROFILE cluster profile"
		exit 1
	else
		echo $result
	fi
}

function IngressTFCrutch() {
       for file in $(find $1 -type f -name "*.tf" ! \( \
       -name "main.tf" -o \
       -name "versions.tf" -o \
       -name "variables.tf" -o \
       -name "$(GetParam 'cluster_type' | awk -F\/ '{print $1}').tf" \)); do
               # Rename extra provider tf files :/
               mv "$file" "$file.bak"
       done
}

function TerraformRun() {
	MODULES_ROOT="/opt/legion/terraform/env_types/$(GetParam 'cluster_type')/"
	TF_MODULE=$1
	TF_COMMAND=$2
	WORK_DIR=$MODULES_ROOT/$TF_MODULE

	cd $WORK_DIR
	export TF_DATA_DIR="/tmp/.terraform/$(GetParam 'cluster_name')/$TF_MODULE"
	case $(GetParam "cluster_type") in
		"aws/eks")
			terraform init -no-color \
				-backend-config="bucket=$(GetParam 'tfstate_bucket')" \
				-backend-config="region=$(GetParam 'aws_region')"
			;;
		"gcp/gke")
			terraform init -no-color \
				-backend-config="bucket=$(GetParam 'tfstate_bucket')" \
				-backend-config="prefix=$TF_MODULE"
			;;
		"azure/aks")
			terraform init -no-color \
				-backend-config="container_name=$(GetParam 'tfstate_bucket')" \
				-backend-config="resource_group_name=$(GetParam 'azure_resource_group')" \
				-backend-config="storage_account_name=$(GetParam 'azure_storage_account')" \
				-backend-config="key=$TF_MODULE/default.tfstate"
			;;
	esac

	echo "INFO : Execute $TF_COMMAND on $TF_MODULE state"
	terraform $TF_COMMAND -no-color -auto-approve -var-file=$PROFILE
}

function SetupCloudAccess() {
	echo "INFO : Activating service account"
	case $(GetParam 'cluster_type') in
		"aws/eks")
			;;
		"gcp/gke")
			# Read GCP credentials path from env
			if [[ -z $GOOGLE_CREDENTIALS || ! -f $GOOGLE_CREDENTIALS ]]; then
				echo -e "ERROR:\tNo GCP credentials file found!"
				echo -e "\tPass path to the credentials json file as GOOGLE_CREDENTIALS env var!"
				exit 1
			fi
			gcloud auth activate-service-account --key-file=$GOOGLE_CREDENTIALS --project=$(GetParam 'project_id')
			;;
		"azure/aks")
			if [[ $VERBOSE == true ]]; then set +x; fi
			if [[ -z $ARM_CLIENT_ID || -z $ARM_CLIENT_SECRET || -z $ARM_TENANT_ID || -z $ARM_SUBSCRIPTION_ID ]]; then
				echo -e "ERROR:\tNo Azure Cloud credentials provided!"
				echo -e "\tDeclare ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID env vars!"
				exit 1
			fi
			az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
			export TF_VAR_sp_client_id=${ARM_CLIENT_ID}
			export TF_VAR_sp_secret=${ARM_CLIENT_SECRET}
			if [[ $VERBOSE == true ]]; then set -x; fi
			;;
		*)
			echo "ERROR: 'cluster_type' is not defined or has wrong value"
			exit 1
			;;
	esac
}

# Create Legion cluster
function TerraformCreate() {
	echo 'INFO : Applying k8s create TF module'
	case $(GetParam "cluster_type") in
		"aws/eks")
			TerraformRun eks_create apply
			;;
		"gcp/gke")
			TerraformRun gke_create apply
			;;
		"azure/aks")
			TerraformRun aks_create apply
			;;
	esac
	FetchKubeConfig
	echo 'INFO : Init HELM'
	TerraformRun helm_init apply
	echo 'INFO : Setup K8S Legion dependencies'
	TerraformRun k8s_setup apply
	echo 'INFO : Deploy Legion components'
	TerraformRun legion apply
}

# Destroy Legion cluster
function TerraformDestroy() {
	if CheckCluster; then
		FetchKubeConfig
		echo 'INFO : Init HELM'
		helm init --client-only

		echo 'INFO : Destroy Legion components'
		TerraformRun legion destroy
		echo 'INFO : Destroy K8S Legion dependencies'
		TerraformRun k8s_setup destroy
		echo 'INFO : Destroy Helm'
		TerraformRun helm_init destroy
		rm -rf ~/.kube
	else
		echo "ERROR: There is no cluster found with name \"$(GetParam 'cluster_name')\""
	fi
	case $(GetParam 'cluster_type') in
		"aws/eks")
			echo 'INFO : Destroy EKS cluster'
			TerraformRun eks_create destroy
			;;
		"gcp/gke")
			echo 'INFO : Remove auto-generated fw rules'
			fw_filter="name:k8s- AND network:$(GetParam 'cluster_name')-vpc"
			for i in $(gcloud compute firewall-rules list --filter="${fw_filter}" --format='value(name)' --project=$(GetParam 'project_id')); do
				gcloud compute firewall-rules delete $i --quiet
			done
			echo 'INFO : Destroy GKE cluster'
			TerraformRun gke_create destroy
			;;
		"azure/aks")
			echo 'INFO : Destroy AKS cluster'
			TerraformRun aks_create destroy
			;;
	esac
}

# Check that k8s cluster exists
function CheckCluster() {
	case $(GetParam 'cluster_type') in
		"aws/eks")
			if aws eks list-clusters --region $(GetParam 'aws_region') | grep $(GetParam 'cluster_name'); then
				true
			else
				false
			fi
			;;
		"gcp/gke")
			if gcloud container clusters list --zone $(GetParam 'location') | grep -E "^$(GetParam 'cluster_name') .*"; then
				true
			else
				false
			fi
			;;
		"azure/aks")
			if az aks list --resource-group $(GetParam 'azure_resource_group') --query [].name -o tsv | grep -E "^$(GetParam 'cluster_name')$"; then
				true
			else
				false
			fi
			;;
	esac
}

# Get kubeconfig from deployed cluster
function FetchKubeConfig() {
	echo 'INFO : Authorize Kubernetes API access'
	case $(GetParam "cluster_type") in
		"aws/eks")
			aws eks --region $(GetParam 'aws_region') update-kubeconfig --name $(GetParam 'cluster_name')
			;;
		"gcp/gke")
			gcloud container clusters get-credentials $(GetParam 'cluster_name') --zone $(GetParam 'location') --project=$(GetParam 'project_id')
			;;
		"azure/aks")
			az aks get-credentials --name $(GetParam 'cluster_name') --resource-group $(GetParam 'azure_resource_group')
			;;
	esac
}


##################
### Do the job
##################

ReadArguments "$@"
SetupCloudAccess

export TF_IN_AUTOMATION=true
export TF_PLUGIN_CACHE_DIR=/tmp/.terraform/cache && mkdir -p $TF_PLUGIN_CACHE_DIR
export MODULES_ROOT="/opt/legion/terraform/env_types/$(GetParam 'cluster_type')"

IngressTFCrutch "$MODULES_ROOT/../../../modules/k8s/nginx-ingress/"

if [[ $COMMAND == 'create' ]]; then
	TerraformCreate
elif [[ $COMMAND == 'destroy' ]]; then
	TerraformDestroy
fi
