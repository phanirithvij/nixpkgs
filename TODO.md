## BigBlueButton

- [ ] (high) Dedicated migration commit
  - [ ] Dedicated stb derivation commit
  - [ ] Then update commit
  - [ ] Dedicated commits per new package
    - [ ] Package all required components
      - [ ] mediasoup source build
      - [ ] libwebsockets correct fix
    - [ ] Check what is optional for BBB and deprioritize
    - [ ] Expose package set properly if not in by-name
      - [ ] duplicate mkScope as of now
- [ ] (high) Nixos module with all required components
- [ ] (high) Nixos test basic
- [ ] (high) Update script and documentation on how to maintain this
- [ ] (low) SBT derivation be made into a builder but now I will leave it in bbb
  - [ ] (low) pkgs/by-name if possible after buildSbtPackage or mkSbtDerivation
