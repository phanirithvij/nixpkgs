{ fetchgit, ... }:
fetchgit {
  url = "https://github.com/CollaboraOnline/online.mirror";
  rev = "coda-26.04.3.3-1";
  hash = "sha256-uluBIhFWAyyRxvy/FqdPateaZ/Xb4f94lvi8gQcbokU=";
  fetchSubmodules = false;
}
