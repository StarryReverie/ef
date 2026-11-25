machine.wait_for_unit("user@0.service")
machine.wait_for_unit("maid-activation.service", "root")

root = machine.succeed("getent passwd root").strip()
assert root.endswith("/bin/zsh"), root

alias = machine.succeed("zsh -ic 'alias vi'").strip()
assert alias == "vi=hx", alias

editor = machine.succeed("zsh -lc 'print -r -- $EDITOR'").strip()
assert editor == "hx", editor

visual = machine.succeed("zsh -lc 'print -r -- $VISUAL'").strip()
assert visual == "hx", visual

helix_config = machine.succeed("cat /root/.config/helix/config.toml")
assert 'insert = "INSERT"' in helix_config, helix_config
