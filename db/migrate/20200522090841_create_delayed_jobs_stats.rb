class CreateDelayedJobsStats < ActiveRecord::Migration
  
  def self.up
    create_table :delayed_jobs_stats, :force => true do |table|
      table.integer  :attempt, :null => false                 # Provides for retries, but still fail eventually.
      table.integer  :entity_id, :null => false               # Provides for retries, but still fail eventually.
      table.text     :entity_name, :null => false                  # reason for last failure (See Note below)
      table.text     :status, :default => 'pending', :null => false                  # reason for last failure (See Note below)
      table.datetime :run_at                                  # When to run. Could be Time.zone.now for immediately, or sometime in the future.
      table.datetime :started_at                                  # When to run. Could be Time.zone.now for immediately, or sometime in the future.
      table.integer  :wait_time                               # wait_time in seconds
      table.integer  :execution_time                          # execution_time in seconds
      table.datetime :locked_at                               # Set when a client is working on this object
      table.datetime :compled_at                              # 
      table.text     :last_error                              # reason for last failure (See Note below)
      table.timestamps
    end

    add_index :delayed_jobs_stats, :entity_id
    add_index :delayed_jobs_stats, :created_at
  end

  def self.down
    drop_table :delayed_jobs_stats
  end

end

