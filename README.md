# emb-tools
Scripts to support embedded use of Linux.

# Structure

## Top-level directory
Distro-independent scripts:

- iso-pkg-adds-dels.sh
	- Arguments: iso1-or-path1, iso2-or-path2
	- Output: Packages added and deleted in iso2-or-paths

## suse directory
Scripts for use with SUSE deliverables (e.g., SLE isos, SUSE update channels).

- autoyast-pkgs-iso.sh
	- Arguments: autoyast-profile, iso-or-path
	- Output: autoyast profile packages that are not provided by iso-or-path 

- autoyast-pkgs-repos.sh
	- Arguments: autoyast-profile
	- Options: -d(ebug)
		   -r(epo) (default is to use all registered repos)
	- Output: autoyast profile packages that not provided by registered repos (both enabled and disabled)
