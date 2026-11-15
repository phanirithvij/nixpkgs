{
  pkgs,
  evalSystem,
}:
let
  node = evalSystem {
    system.stateVersion = "26.11";
    programs.zsh = {
      enable = true;
      ohMyZsh.enable = true;
    };
  };
in
pkgs.runCommand "oh-my-zsh-test"
  {
    nativeBuildInputs = [ pkgs.zsh ];
    meta.maintainers = [ ];
  }
  ''
    HOME=$(mktemp -d)
    export HOME
    touch "$HOME/.zshrc"

    # Verify that the generated zshrc exports ZSH pointing to the expected oh-my-zsh path
    grep -F "oh-my-zsh-${pkgs.oh-my-zsh.version}" "${node.config.environment.etc."zshrc".source}"

    # Verify that sourcing the generated configuration in zsh sets ZSH appropriately
    zsh -c 'source "${node.config.environment.etc."zshrc".source}" 2>/dev/null && echo "$ZSH" | grep "oh-my-zsh-${pkgs.oh-my-zsh.version}"'

    touch $out
  ''
