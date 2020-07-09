class AddHostnameToDelayedJobsStats < ActiveRecord::Migration
   def change
    add_column :delayed_jobs_stats, :hostname, :string
  end
end
