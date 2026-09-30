{ config, lib, pkgs, ... }:

let
  cfg = config.homebrew;
  brew = "${cfg.prefix}/bin/brew";

  brewfile = pkgs.writeText "Brewfile" (lib.concatLines (
    map (tap: ''tap "${tap}"'') cfg.taps
    ++ map (formula: ''brew "${formula}"'') cfg.formulae
  ));

  shellInit = ''
    if [ -x ${brew} ]; then
      eval "$(${brew} shellenv)"
    fi
  '';
in
{
  options.homebrew = {
    enable = lib.mkEnableOption "declarative Homebrew formulae";

    prefix = lib.mkOption {
      type = lib.types.str;
      default = "/home/linuxbrew/.linuxbrew";
      description = "Homebrew install prefix. bootstrap.sh installs it here.";
    };

    taps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Taps to add, e.g. \"hashicorp/tap\".";
    };

    formulae = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Formulae to install.";
    };

    cleanup = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Uninstall every formula and tap that is not listed in `formulae` or
        `taps`, including ones installed by hand with `brew install`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."homebrew/Brewfile".source = brewfile;
    home.sessionVariables.HOMEBREW_BUNDLE_FILE = "${config.xdg.configHome}/homebrew/Brewfile";

    programs.zsh.initContent = lib.mkOrder 550 shellInit;
    programs.bash.initExtra = lib.mkOrder 550 shellInit;

    home.activation.homebrewBundle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -x ${brew} ]; then
        warnEcho "Homebrew not found at ${brew}; skipping formulae. Run ./bootstrap.sh to install it."
      else
        export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1
        if ! ${brew} bundle check --file=${brewfile} --no-upgrade >/dev/null 2>&1; then
          run ${brew} bundle install --file=${brewfile} --no-upgrade
        fi
        ${lib.optionalString cfg.cleanup ''
          run ${brew} bundle cleanup --file=${brewfile} --formula --tap --force
        ''}
      fi
    '';
  };
}
