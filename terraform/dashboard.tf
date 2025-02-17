resource "grafana_dashboard" "postgresql_performance" {
  config_json = jsonencode({
    title = "PostgreSQL Performance Dashboard"
    description = "Key performance metrics for PostgreSQL database"
    tags = ["postgresql", "performance"]
    timezone = "browser"
    refresh = "5s"
    editable = true
    panels = [
      {
        id = 1
        title = "CPU Usage"
        type = "timeseries"
        gridPos = {
          h = 8
          w = 12
          x = 0
          y = 0
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = <<-EOF
                SELECT
                    now() - interval '1 hour' + interval '1 minute' * generate_series(0, 59) AS time,
                    (SELECT SUM(total_exec_time) / 1000 FROM pg_stat_statements) AS value
                ORDER BY time;
            EOF
            format = "time_series"
          }
        ]
      },
      {
        id = 2
        title = "Memory Usage"
        type = "timeseries"
        gridPos = {
          h = 8
          w = 12
          x = 12
          y = 0
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = <<-EOF
              SELECT
                now() - interval '1 hour' + interval '1 minute' * generate_series(0, 59) AS time,
                pg_database_size(current_database()) / 1024.0 / 1024.0 AS value
              FROM generate_series(1, 60)
              ORDER BY time;
            EOF
            format = "time_series"
          }
        ]
      },
      {
        id = 3
        title = "Active Connections"
        type = "gauge"
        gridPos = {
          h = 8
          w = 8
          x = 0
          y = 8
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = "SELECT NOW() as time, count(*) as value FROM pg_stat_activity WHERE state = 'active';"
            format = "time_series"
          }
        ]
      },
      {
        id = 4
        title = "Transaction Throughput"
        type = "timeseries"
        gridPos = {
          h = 8
          w = 8
          x = 8
          y = 8
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = <<-EOF
              SELECT
                now() - interval '1 hour' + interval '1 minute' * generate_series(0,59) as time,
                (SELECT xact_commit + xact_rollback FROM pg_stat_database WHERE datname = current_database()) as value
              FROM generate_series(1,60)
              ORDER BY time;
            EOF
            format = "time_series"
          }
        ]
      },
      {
        id = 5
        title = "Cache Hit Ratio"
        type = "gauge"
        gridPos = {
          h = 8
          w = 8
          x = 16
          y = 8
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = <<-EOF
                  SELECT 
                    NOW() as time,
                    ROUND(
                      (SUM(blks_hit) * 100.0) / NULLIF(SUM(blks_hit + blks_read), 0), 
                      2
                    ) as cache_hit_ratio,
                    SUM(blks_hit) as total_hits,
                    SUM(blks_read) as total_reads
                  FROM pg_stat_database
                  WHERE datname = current_database();
            EOF
            format = "time_series"
          }
        ]
      }
    ]
  })
}