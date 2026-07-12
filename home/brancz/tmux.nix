# home/brancz/tmux.nix
{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    keyMode = "vi";
    mouse = true;
    baseIndex = 1;
    escapeTime = 0;       # no ESC delay — matters in neovim
    historyLimit = 100000;
    prefix = "C-a";       # C-b collides with vim's page-up

    # Plugins come from nixpkgs (pkgs.tmuxPlugins.*) — no TPM, no
    # `prefix + I` install step, fully pinned by your flake.lock.
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];

    extraConfig = ''
      # true color + undercurl passthrough (ghostty)
      set -ga terminal-features ",xterm-ghostty:RGB"
      set -ga terminal-features ",*:usstyle"

      # companions to prefix = C-a
      bind-key C-a last-window   # C-a C-a toggles between the last two windows
      bind-key a   send-prefix   # C-a a sends a literal C-a (nested tmux, or readline)

      # splits inherit cwd
      bind '"' split-window -v -c "#{pane_current_path}"
      bind %   split-window -h -c "#{pane_current_path}"
      bind c   new-window      -c "#{pane_current_path}"

      # vim-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # vi-mode copy that actually copies (uses yank plugin under the hood)
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-selection-and-cancel

      set -g renumber-windows on
      set -g set-clipboard on
      set -g focus-events on
    '';
  };
}
