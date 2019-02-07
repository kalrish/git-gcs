set -e

function command_archive {
	git bundle create "${1:-${PWD##*/}.bundle}" --all
}

function command_export {
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
		
		gpg --encrypt "${key_args[@]}" "${store}/store.yaml"
	else
		echo 'error: store name not specified'
		return 1
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
				echo "error: unknown subcommand '${subcommand}'"
				return 1
			fi
		else
			echo 'error: missing subcommand'
			return 1
		fi
	else
		echo 'error: missing subcommand'
		return 1
	fi
}

exec > >(sed -e 's/^/git-gcs: /' >&2)

command "$@"
