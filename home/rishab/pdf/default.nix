{ ... }: {
  programs.sioyek = {
    enable = true;
    bindings = {
      "toggle_custom_color" = "i";
      "goto_prev_tab" = "<Ctrl h>";
      "goto_next_tab" = "<Ctrl l>";
    };
    config = {
      "ui_font" = "Maple Mono NF CN";
      "font_size" = "15";

      "fit_to_page_width_on_open" = "1";

      "page_space_y" = "10";
    };
  };
}
