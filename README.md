# emb-tools
Scripts to support embedded use of Linux.

# Structure

## Top-level directory - Distro-Independent Scripts

iso-pkg-adds-dels.sh: Compare 2 isos (or paths), list the packages added and deleted on the second iso (or path).
    - Arguments: iso1-or-path1, iso2-or-path2
    - Options: -h(elp), -d(ebug)
    - Output: Packages added and deleted in iso2-or-path2

## suse directory - Scripts for Use with SUSE Distros

autoyast-pkgs-iso.sh: Compare an autoyast profile to an iso (or path), list the packages not found on the iso (or path).
    - Arguments: autoyast-profile, iso-or-path
    - Options: -h(elp), -d(ebug)
    - Output: autoyast profile packages that are not provided by iso-or-path 

autoyast-pkgs-repos.sh: Compare an autoyast profile to repo(s), list the packages not found in the repo(s).
    - Arguments: autoyast-profile
    - Options: -h(elp), -d(ebug), -r(epo) (default is to use all registered repos)
    - Output: autoyast profile packages that not provided by registered repos (both enabled and disabled)
