{ stdenvNoCC, fetchgit, lib }:

let
  inherit (lib)
    attrNames
    concatStringsSep
    escapeShellArg
    mapAttrsToList
    unique
  ;

  #
  # JSON file with two "data" keys:
  #  - directories, list of directories to directly move as an output
  #  - files, attrset of `outputName: [ patterns ]`, patterns will be moved into the given output
  #
  # Note that a file pattern can move a file in a previously defined `directories` pattern. See e.g. `qcom`
  #
  splitsData = builtins.fromJSON (builtins.readFile ./splits.json);
  splits = splitsData // {
    outputs = unique (splitsData.directories ++ (attrNames splitsData.files));
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "firmware-linux-nonfree";
  version = "20211027";

  src = fetchgit {
    url = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    rev = "refs/tags/${version}";
    sha256 = "00vv617ngr8rfrm1rw98xxgc453zb8cb5p8ssz5s3khynpqqg08x";
  };

  outputs = [ "out" ] ++ (splits.outputs);
  installFlags = [ "DESTDIR=../staged_output" ];

  postInstall = ''(
    mkdir -p $out/lib/firmware
    cd ../staged_output/lib/firmware

    ${concatStringsSep "\n" (map (destination:
    let
      destination' = escapeShellArg destination;
      destinationParent = escapeShellArg "${placeholder destination}/lib/firmware/";
      destinationDir = escapeShellArg "${placeholder destination}/lib/firmware/${destination}";
    in
    ''
      echo
      echo " :: Moving "${destination'}" (${placeholder destination})"
      mkdir -pv ${destinationParent}
      mv -v ${destination'} ${destinationParent}
      ln -vs ${destinationDir} "$out/lib/firmware/"${destination'}
    '') splits.directories)}

    ${concatStringsSep "\n" (mapAttrsToList (destination: patterns:
    let
      destination' = escapeShellArg destination;
      destinationDir = escapeShellArg "${placeholder destination}/lib/firmware";
    in
    ''
      echo
      echo " :: Moving files for "${destination'}" (${placeholder destination})"
      mkdir -pv ${destinationDir}
      mv -vt ${destinationDir} ${concatStringsSep " " patterns}
      ln -vst "$out/lib/firmware/" ${concatStringsSep " " (map (p: "${destinationDir}/${p}") patterns)}
    '') splits.files)}


    echo
    echo "Checking that all firmware files were handled correctly..."

    fail=0
    
    # First check no files are left in the staged_output
    for name in *; do
      fail=1
      type=file
      test -d "$name" && type=directory
      printf " -> ERROR: Unexpected %s '%s' left in staged_output...\n" "$type" "$name"
    done

    # Then check all symlinks were handled correctly
    (
      cd $out/lib/firmware
      for name in *; do
        if ! readlink -f "$name" > /dev/null; then
          fail=1
          target="$(readlink "$(readlink "$name")")"
          printf " -> ERROR: Symlink %s is left dangling (target is: '%s')...\n" "$name" "$target"
          echo   "    Tip: putting this file in the same output as the first component of this target should fix the problem."
        fi
      done
    )

    [[ $fail == 0 ]]

    echo "... done"
  )'';

  # Firmware blobs do not need fixing and should not be modified
  dontFixup = true;

  meta = with lib; {
    description = "Binary firmware collection packaged by kernel.org";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = licenses.unfreeRedistributableFirmware;
    platforms = platforms.linux;
    maintainers = with maintainers; [ fpletz ];
    priority = 6; # give precedence to kernel firmware
  };

  passthru = { inherit version; };
}
