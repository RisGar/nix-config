{ ... }: {
  programs.sioyek = {
    enable = true;
    bindings = {
      "toggle_custom_color" = "i";
      "goto_prev_tab" = "<Ctrl h>";
      "goto_next_tab" = "<Ctrl l>";

      "toggle_freehand_drawing_mode" = "d";
    };
    config = {
      "ui_font" = "Maple Mono NF CN";
      "font_size" = "15";
      "fit_to_page_width_on_open" = "1";
      "page_padding_y" = "10";
    };
  };
}
