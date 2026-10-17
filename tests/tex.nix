# Evaluate with: nix eval .#darwinConfigurations.fresh-mac --apply 'import ./tests/tex.nix'
# Package/format wiring only: this does not build or run a TeX engine.
native:
let
  inherit (native.pkgs) lib;
  config = native.config;
  home = config.home-manager.users.${config.system.primaryUser};
  environments = builtins.filter (p: p ? includedTeXPackages) home.home.packages;
  tex = builtins.head environments;
  included = lib.unique (map (p: p.pname) tex.includedTeXPackages);
  required = [
    "pdftex" "latex-bin" "xetex" "latexmk" "amsmath" "graphics" "booktabs"
    "fontspec" "unicode-math" "lm" "tex-gyre" "babel-english" "babel-italian"
    "hyphen-italian" "bibtex" "biblatex" "biber" "makeindex"
  ];
  excluded = [ "ketcindy" "arara" "bib2gls" "texworks" "tlshell" "xdvi" "context" ];
in
assert lib.assertMsg (builtins.length environments == 1) "Expected one TeX package owner";
assert lib.assertMsg (lib.all (p: !(builtins.elem p included)) excluded) "Unrelated TeX extras remain selected";
assert lib.assertMsg (lib.all (p: builtins.elem p included) required) "A promised PDF compilation component is missing";
assert lib.assertMsg (lib.all (s: lib.hasInfix s tex.fmtutilCnf) [ "\npdflatex pdftex " "\nxelatex xetex " ]) "PDF format definitions are missing";
assert lib.assertMsg (lib.hasInfix "italian loadhyph-it.tex" tex.languageDat) "Italian hyphenation is missing";
assert lib.assertMsg (!(builtins.elem "texstudio" (map (c: c.name) config.homebrew.casks))) "TeXstudio must be excluded";
{
  derivation = tex.drvPath;
  packages = included;
  formats = tex.fmtutilCnf;
  languages = tex.languageDat;
}
