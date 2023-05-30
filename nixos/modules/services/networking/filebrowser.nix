{ config, lib, options, pkgs, ... }:

with lib;

let
  cfg = config.services.filebrowser;
  defaultUser = "filebrowser";
  defaultGroup = defaultUser;
in {

  options = {
    services.filebrowser = {
      enable = mkEnableOption
        (lib.mdDoc "File Browser, a self-hosted file browser to access your files from a web interface");

      user = mkOption {
        type = types.str;
        default = defaultUser;
        example = "yourUser";
        description = mdDoc ''
          The user to run File Browser as.

          By default, a user named `${defaultUser}` will be created.
        '';
      };

      group = mkOption {
        type = types.str;
        default = defaultGroup;
        example = "yourGroup";
        description = mdDoc ''
          The group to run File Browser under.

          By default, a group named `${defaultGroup}` will be created.
        '';
      };

      address = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = mdDoc ''
          Address to listen on.
        '';
      };

      port = mkOption {
        type = lib.types.port;
        default = 8080;
        description = mdDoc ''
          Port to listen on.
        '';
      };

      baseUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "https://example.org";
        description = lib.mdDoc ''
          The base URL from which File Browser is accessed.
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/filebrowser";
        example = "/home/yourUser";
        description = lib.mdDoc ''
          The path where File Browser will store its settings.
        '';
      };

      root = mkOption {
        type = types.path;
        default = "${cfg.dataDir}/files";
        defaultText = literalExpression ''"''${cfg.dataDir}/files"'';
        example = "/home/yourUser";
        description = lib.mdDoc ''
          Root to prepend to relative paths, the path that File Browser will expose.
        '';
      };

      initialUsername = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "admin";
        description = mdDoc ''
          Name of the first user created by File Browser.

          This option can be set to null once File Browser has initialized once.

          If set to null, File Browser will create a first user named 'admin'.
        '';
      };

      initialHashedPassword = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "admin";
        description = mdDoc ''
          Password of the first user created by File Browser.

          This option can be set to null once File Browser has initialized once.

          To generate a hashed password run `filebrowsher hash <password>`.

          If set to null, File Browser will create a user with the password 'admin'.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    users.users = mkIf (cfg.user == defaultUser) {
      ${defaultUser} =
        { group = cfg.group;
          home  = cfg.dataDir;
          createHome = true;
          uid = config.ids.uids.filebrowser;
          description = "File Browser daemon user";
        };
    };

    users.groups = mkIf (cfg.group == defaultGroup) {
      ${defaultGroup}.gid =
        config.ids.gids.filebrowser;
    };

    systemd.packages = [ pkgs.filebrowser ];

    systemd.services = {
      filebrowser = {
        description = "File Browser service";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Restart = "on-failure";
          User = cfg.user;
          Group = cfg.group;

          ExecStartPre = ''
            ${pkgs.coreutils}/bin/mkdir -p ${cfg.root}
          '';

          ExecStart = ''
            ${pkgs.filebrowser}/bin/filebrowser \
            --address=${cfg.address} \
            --port=${toString(cfg.port)} \
            --database=${cfg.dataDir}/filebrowser.db \
            --root=${cfg.root} \
            ${optionalString (isString cfg.baseUrl) "--baseurl=${toString(cfg.baseUrl)} "} \
            ${optionalString (isString cfg.initialUsername) "--username=${toString(cfg.initialUsername)} "} \
            ${optionalString (isString cfg.initialHashedPassword) "--password=${toString(cfg.initialHashedPassword)}"}
          '';
        };
      };
    };
  };
}
