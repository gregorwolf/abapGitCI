# abapGit CI

## Setup

NetWeaver Developer Edition https://github.com/sbcgua/sap-nw-abap-vagrant
Import GitHub Certificate Chain (STRUST)
Installation of abapGit via report
Installation of abapGit from GitHub

## Functionality

* Update abapGit using the report ZABAPGIT_CI_UPDATE 
* Install all abapGit-tests Repositories with the report ZABAPGIT_CI_TESTS 
  * Read list of abapGit-tests Repositories using the GitHub API https://api.github.com/orgs/abapGit-tests/repos
  * Install the repositories as local packages
