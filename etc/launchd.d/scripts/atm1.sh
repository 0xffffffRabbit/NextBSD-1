#!/bin/sh
#
# Removed dependency from /etc/rc.

# ATM networking startup script
#
# Initial interface configuration.
# N.B. /usr is not mounted.
#
atm_start()
{
	if [ -n "${natm_interfaces}" ] ; then
		# Load the HARP pseudo interface
		kldstat -v | grep -q if_harp || kldload if_harp

		# Load all the NATM drivers that we need
		for natm in ${natm_interfaces} ; do
			ifconfig ${natm} up
		done
	fi

	# Load loadable HARP drivers
	for dev in ${atm_load} ; do
		kldstat -v | grep -q ${dev} || kldload ${dev}
	done

	# Locate all probed ATM adapters
	atmdev=`atm sh stat int | while read dev junk; do
		case ${dev} in
		hea[0-9] | hea[0-9][0-9])
			echo "${dev} "
			;;
		hfa[0-9] | hfa[0-9][0-9])
			echo "${dev} "
			;;
		idt[0-9] | idt[0-9][0-9])
			echo "${dev} "
			;;

		# NATM interfaces per pseudo driver
		en[0-9] | en[0-9][0-9])
			echo "${dev} "
			;;
		fatm[0-9] | fatm[0-9][0-9])
			echo "${dev} "
			;;
		hatm[0-9] | hatm[0-9][0-9])
			echo "${dev} "
			;;
		patm[0-9] | patm[0-9][0-9])
			echo "${dev} "
			;;
		*)
			continue
			;;
		esac
	done`

	if [ -z "${atmdev}" ]; then
		echo 'No ATM adapters found'
		return 0
	fi

	# Load microcode into FORE adapters (if needed)
	if [ `expr "${atmdev}" : '.*hfa.*'` -ne 0 ]; then
		fore_dnld
	fi

	# Configure physical interfaces
	ilmid=0
	for phy in ${atmdev}; do
		echo -n "Configuring ATM device ${phy}:"

		# Define network interfaces
		eval netif_args=\$atm_netif_${phy}
		if [ -n "${netif_args}" ]; then
			atm set netif ${phy} ${netif_args} || continue
		else
			echo ' missing network interface definition'
			continue
		fi

		# Override physical MAC address
		eval macaddr_args=\$atm_macaddr_${phy}
		if [ -n "${macaddr_args}" ]; then
			case ${macaddr_args} in
			[Nn][Oo] | '')
				;;
			*)
				atm set mac ${phy} ${macaddr_args} || continue
				;;
			esac
		fi

		# Configure signalling manager
		eval sigmgr_args=\$atm_sigmgr_${phy}
		if [ -n "${sigmgr_args}" ]; then
			atm attach ${phy} ${sigmgr_args} || continue
		else
			echo ' missing signalling manager definition'
			continue
		fi

		# Configure UNI NSAP prefix
		eval prefix_args=\$atm_prefix_${phy}
		if [ `expr "${sigmgr_args}" : '[uU][nN][iI].*'` -ne 0 ]; then
			if [ -z "${prefix_args}" ]; then
				echo ' missing NSAP prefix for UNI interface'
				continue
			fi

			case ${prefix_args} in
			ILMI)
				ilmid=1
				;;
			*)
				atm set prefix ${phy} ${prefix_args} || continue
				;;
			esac
		fi

		atm_phy="${atm_phy} ${phy}"
		echo '.'
	done

	echo -n 'Starting initial ATM daemons:'
	# Start ILMI daemon (if needed)
	case ${ilmid} in
	1)
		echo -n ' ilmid'
		ilmid -f
		;;
	esac

	echo '.'
}

# start here
# used to emulate "requires/provide" functionality
pidfile="/var/run/atm1.pid"
touch $pidfile

atm_start

exit 0
