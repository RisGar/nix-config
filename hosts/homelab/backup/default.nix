{ config, lib, pkgs, ... }:
let
  dataDir = "/mnt/external";

  # staging area for consistent sqlite dumps
  prepareDir = "/var/lib/restic-prepare";

  coreutils = "${pkgs.coreutils}/bin";
  sqlite3 = lib.getExe pkgs.sqlite;

  # state directories of the services whose data is worth restoring
  serviceDirs = [
    "/var/lib/caddy" # internal CA, autosaved config
    "/var/lib/dawarich" # public/ files
    "/var/lib/grafana" # dashboards, users, datasources
    "/var/lib/immich" # ml state/config; the media itself is on dataDir
    "/var/lib/jellyfin" # library db, metadata, watch state
    "/var/lib/papra" # documents are on dataDir, the db is dumped separately
    "/var/lib/pocket-id" # identity provider state, everything depends on it
    "/var/lib/samba" # samba state and usershares
    "/var/lib/stump" # manga library
    "/var/lib/tandoor-recipes" # media/static
    "/var/lib/transmission" # torrent resume state
  ];

  # a running service may hold unflushed WAL pages, so they are copied with `sqlite3 .backup` instead of being read in place
  sqliteDBs = [
    {
      name = "papra";
      src = "/var/lib/papra/db.sqlite";
      dest = "papra.sqlite";
    }
    {
      name = "pocket-id";
      src = "/var/lib/pocket-id/data/pocket-id.db";
      dest = "pocket-id.sqlite";
    }
    {
      name = "grafana";
      src = "/var/lib/grafana/data/grafana.db";
      dest = "grafana.sqlite";
    }
    {
      name = "stump";
      src = "/var/lib/stump/stump.db";
      dest = "stump.sqlite";
    }
    {
      name = "jellyfin";
      src = "/var/lib/jellyfin/data/jellyfin.db";
      dest = "jellyfin.sqlite";
    }
  ];

  dumpSqlite = db: ''
    if [ -f ${db.src} ]; then
      ${sqlite3} ${db.src} ".backup '${prepareDir}/${db.dest}'"
    else
      echo "restic prepare: ${db.src} not found, skipping ${db.name}" >&2
    fi
  '';
in
{
  imports = [
    # status metrics + Grafana dashboard, hooks itself onto the restic unit
    ./metrics.nix
  ];

  # Postgres (immich, dawarich, tandoor_recipes) is dumped by NixOS itself: it
  # keeps the current and the previous dump of every database in
  # /var/backup/postgresql, which restic then picks up. If a dump fails, the
  # previous one is still there.
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    startAt = "02:30"; # before the restic run below
    compression = "zstd";
    compressionLevel = 10;
  };

  services.restic.backups.homelab = {
    environmentFile = config.sops.secrets.restic.path;
    initialize = true;

    paths = [
      dataDir
      prepareDir
      "/var/backup/postgresql"
    ]
    ++ serviceDirs;

    exclude = [
      # TimeMachine and media libraries
      "${dataDir}/TimeMachine"
      "${dataDir}/Library"
      "${dataDir}/Movies"
      "${dataDir}/TV"
      "${dataDir}/Movies_Anime"
      "${dataDir}/TV_Anime"
      "${dataDir}/Manga"
      "${dataDir}/.Trash-0"
      "${dataDir}/.Trash-1000"
    ]
    # live sqlite files are replaced by the dumps from backupPrepareCommand
    ++ lib.concatMap (db: [
      db.src
      "${db.src}-wal"
      "${db.src}-shm"
    ]) sqliteDBs;

    backupPrepareCommand = ''
      set -euo pipefail
      ${coreutils}/install -d -m 0700 ${prepareDir}
      ${lib.concatMapStringsSep "\n" dumpSqlite sqliteDBs}
    '';

    backupCleanupCommand = ''
      ${coreutils}/rm -rf ${prepareDir}
    '';

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];

    extraBackupArgs = [
      "--tag"
      "homelab"
    ];

    timerConfig = {
      OnCalendar = "03:30";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };

  systemd.services.restic-backups-homelab.unitConfig.RequiresMountsFor = [ dataDir ];
}
