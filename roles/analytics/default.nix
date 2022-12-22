{ config, lib, pkgs, ... }:

let
  cfg = config.my.roles.analytics;
  port = 8035;
in {
  options.my.roles.analytics.enable = lib.mkEnableOption "analytics ingest server";

  config = lib.mkIf cfg.enable {
    services.clickhouse.enable = true;

    systemd.services.analytics-ingest = {
      description = "Analytics ingest server";
      after = [ "network.target" ];
      bindsTo = [ "clickhouse.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        ExecStart = "${pkgs.analytics-ingest}/bin/analytics-ingest --port=${toString port}";

        # clickhouse does not properly use sd-notify to report successful
        # startup. In case we fail due to not being able to connect at startup,
        # retry a few times.
        Restart = "on-failure";
        RestartSec = 3;
      };
    };

    my.http.vhosts."analytics.dolphin-emu.org".proxyLocalPort = port;
    my.monitoring.targets.analytics-ingest.targetLocalPort = port;
  };
}
