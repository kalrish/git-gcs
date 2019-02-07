set -e

source "$(git --exec-path)/git-sh-setup"

function stage_empty {
	git diff --quiet --cached
}

function assert_stage_empty {
	if ! stage_empty
	then
		die 'stage is not empty'
		false
	fi
}

function command_archive {
	git bundle create "${1:-${PWD##*/}.bundle}" --all
}

function command_export {
	declare -A arguments
	arguments[gpg]=gpg
	
	declare -i count=2
	
	for argument in "$@"
	do
		if [[ ${argument} =~ ^\-\-(.*)=(.*)$ ]]
		then
			let ++count
			
			parameter="${BASH_REMATCH[1]}"
			value="${BASH_REMATCH[2]}"
			
			if [[ -v arguments["${parameter}"] ]]
			then
				arguments["${parameter}"]="${value}"
			fi
		else
			store="${argument}"
			break
		fi
	done
	
	if [[ -v store ]]
	then
		for key in "${!arguments[@]}"
		do
			local -- "${key//-/_}=${arguments[${key}]}"
		done
		
		declare -a key_args
		for key in "${store}"/keys/*.asc
		do
			key_args+=(-f)
			key_args+=("${key}")
		done
		
		"${gpg}" --encrypt "${key_args[@]}" "${store}/store.yaml"
	else
		die 'store name not specified'
	fi
}

function command_key_add {
	store_name="${1:?error: store name not specified}"
	key_name="${2:?error: key name not specified}"
	key_identifier="${3:?error: key identifier not supplied}"
	
	assert_stage_empty
	
	path="${stores_dir}/${store_name}/keys/${key_name}.asc"
	gpg ${keyring:+--keyring "${keyring}"} --export --armor --output "${path}" "${key_identifier}"
	git add -- "${path}"
	git commit -m "Let ${key_identifier} access store '${store_name}'"
}

function command_key_delete {
	store_name="${1:?error: store name not specified}"
	key_name="${2:?error: key name not specified}"
	
	assert_stage_empty
	
	git rm -f -- "${store_name}/keys/${key_name}.asc"
	git commit -m "Revoke access to ${store_name} to ${key_name}"
}

function command_key {
	if [[ $# > 0 ]]
	then
		declare -A arguments
		arguments[store]=''
		
		declare -i count=2
		
		for argument in "$@"
		do
			if [[ ${argument} =~ ^\-\-(.*)=(.*)$ ]]
			then
				let ++count
				
				parameter="${BASH_REMATCH[1]}"
				value="${BASH_REMATCH[2]}"
				
				if [[ -v arguments["${parameter}"] ]]
				then
					arguments["${parameter}"]="${value}"
				fi
			else
				subcommand="${argument}"
				break
			fi
		done
		
		if [[ -v subcommand ]]
		then
			funcmd="command_key_${subcommand}"
			if [[ $(type -t -- "${funcmd}") = function ]]
			then
				for key in "${!arguments[@]}"
				do
					export -- "${key//-/_}=${arguments[${key}]}"
				done
				
				"${funcmd}" "${@:${count}}"
			else
				die "unknown git-gcs-key subcommand '${subcommand}'"
			fi
		else
			die 'missing git-gcs-key subcommand'
		fi
	else
		die 'missing git-gcs-key subcommand'
	fi
}

function command_store_create {
	store="${1:?error: store name not specified}"
	
	assert_stage_empty
	
	mkdir -p -- "${store}/keys"
	echo '---' > "${store}/store.yaml"
	echo 'store.yaml.gpg' > "${store}/.gitignore"
	
	git add -- "${store}"
	git commit -m "Create store '${store}'"
	
	say "Store '${store}' created successfully"
	say 'Grant access to it to keys with  git gcs key add'
}

function command_store_remove {
	store="${1:?error: store name not specified}"
	
	assert_stage_empty
	
	git rm -fr -- "${store}"
}

function command_store {
	if [[ $# > 0 ]]
	then
		declare -A arguments
		
		declare -i count=2
		
		for argument in "$@"
		do
			if [[ ${argument} =~ ^\-\-(.*)=(.*)$ ]]
			then
				let ++count
				
				parameter="${BASH_REMATCH[1]}"
				value="${BASH_REMATCH[2]}"
				
				if [[ -v arguments["${parameter}"] ]]
				then
					arguments["${parameter}"]="${value}"
				fi
			else
				subcommand="${argument}"
				break
			fi
		done
		
		if [[ -v subcommand ]]
		then
			funcmd="command_store_${subcommand}"
			if [[ $(type -t -- "${funcmd}") = function ]]
			then
				for key in "${!arguments[@]}"
				do
					export -- "${key//-/_}=${arguments[${key}]}"
				done
				
				"${funcmd}" "${@:${count}}"
			else
				die "unknown git-gcs-store subcommand '${subcommand}'"
			fi
		else
			die 'missing git-gcs-store subcommand'
		fi
	else
		die 'missing git-gcs-store subcommand'
	fi
}

function command {
	if [[ $# > 0 ]]
	then
		declare -A arguments
		
		declare -i count=2
		
		for argument in "$@"
		do
			if [[ ${argument} =~ ^\-\-(.*)=(.*)$ ]]
			then
				let ++count
				
				parameter="${BASH_REMATCH[1]}"
				value="${BASH_REMATCH[2]}"
				
				if [[ -v arguments["${parameter}"] ]]
				then
					arguments["${parameter}"]="${value}"
				fi
			else
				subcommand="${argument}"
				break
			fi
		done
		
		if [[ -v subcommand ]]
		then
			funcmd="command_${subcommand}"
			if [[ $(type -t -- "${funcmd}") = function ]]
			then
				for key in "${!arguments[@]}"
				do
					export -- "${key//-/_}=${arguments[${key}]}"
				done
				
				"${funcmd}" "${@:${count}}"
			else
				die "unknown subcommand '${subcommand}'"
			fi
		else
			die 'missing subcommand'
		fi
	else
		die 'missing subcommand'
	fi
}

exec > >(sed -e 's/^/git-gcs: /' >&2)

command "$@"
