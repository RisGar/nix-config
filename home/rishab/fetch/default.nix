{ ... }:
{
  xdg.configFile."fastfetch/ascii.txt".text = ''
              $1,1C1
            ,CC1
      $2,;11i:;11i11;,
    .tCGGGGGCCCGGGGt.
    $3fGCCCCCCCCCCCCi
    CCCCCCCCCCCCCC,
    $4tGCCCCCCCCCCCCf,
    ,CCCCCCCCCCCCCCG1
     $5,LGCCCGGGCCCCGf.
      .iLLLt11tLLf;
  '';
  programs.fastfetch = {
    enable = true;
    settings = builtins.fromJSON (builtins.readFile ./config.jsonc);
  };
}
