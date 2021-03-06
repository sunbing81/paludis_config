#!/bin/bash

## string parser
remove_comment_and_platform() {
  # removes comments('#'), platform unmask('~'), blank lines, require lines('@require') and bashrc modification lines('@*/*')
  sed -r -e 's/#.*//' -e 's/~//' -e '/^[[:blank:]]*$/d' -e '/^[[:blank:]]*@.*/d'
}

remove_user_mask_spec() {
  # remove spec with user mask('-')
  sed -r -e 's/^[[:blank:]]*-.*//'
}

remove_custom_mark() {
  # remove user mask('-'), mask unmask('+'), and suggestion taken('&')
  sed -e 's/^[[:blank:]]*[+-]\([[:alnum:]]\+\)/\1/' -e 's/&.*//'
}

## for bashrc
has_ipv6() {
	{
		if which ip; then
			ip -6 a | grep inet6 | grep global && return 0
		elif which ifconfig; then
			ifconfig | grep inet6 | grep global && return 0
		fi

		return 1
	} >/dev/null 2>&1
}

is_in_2112() {
	has_ipv6
}

## NOTE this is best done in hooks, but ebuild_configure_pre and src_configure
## are executed in different context; we need to inject enable_distcc into
## src_configure directly
wrap_ebuild_phase() {
	einfo_unhooked "Wrapping the ${EXHERES_PHASE} phase..."

	local group=()
	while [[ "$#" -gt 0 ]]; do
		if [[ "$1" == *';' ]]; then
			## pre hook
			group+=( "${1%;}" )
			einfo_unhooked "  Running the pre-${EXHERES_PHASE} hook ${group[@]}..."
			"${group[@]}"
			group=()
		elif [[ "$#" -eq 1 ]]; then
			group+=( "$1" )

			einfo_unhooked "  Entering the ${EXHERES_PHASE} phase..."

			if [[ ${EXHERES_PHASE} == "configure" ]]; then
				einfo_unhooked "  Applying EXTRA_ECONF..."
				edo "${group[@]}" ${MY__EXTRA_ECONF}
			else
				edo "${group[@]}"
			fi
		else
			group+=( "$1" )
		fi

		shift
	done
}
