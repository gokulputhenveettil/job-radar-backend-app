class CreateUserTrackedJobs < ActiveRecord::Migration[8.1]
  def up
    create_table :user_tracked_jobs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tracked_job, null: false, foreign_key: true
      t.boolean :saved, default: false, null: false
      t.boolean :applied, default: false, null: false
      t.boolean :dismissed, default: false, null: false

      t.timestamps
    end

    add_index :user_tracked_jobs, [ :user_id, :tracked_job_id ], unique: true

    if select_value("SELECT COUNT(*) FROM users").to_i == 1
      execute <<~SQL
        INSERT INTO user_tracked_jobs
          (user_id, tracked_job_id, saved, applied, dismissed, created_at, updated_at)
        SELECT users.id, tracked_jobs.id, tracked_jobs.saved, tracked_jobs.applied,
               tracked_jobs.dismissed, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        FROM users
        CROSS JOIN tracked_jobs
        WHERE tracked_jobs.saved OR tracked_jobs.applied OR tracked_jobs.dismissed
      SQL
    end

    remove_index :tracked_jobs, name: "index_tracked_jobs_on_saved_and_applied_and_created_at"
    remove_index :tracked_jobs, :dismissed if index_exists?(:tracked_jobs, :dismissed)
    remove_column :tracked_jobs, :saved, :boolean, default: false, null: false
    remove_column :tracked_jobs, :applied, :boolean, default: false, null: false
    remove_column :tracked_jobs, :dismissed, :boolean, default: false, null: false
  end

  def down
    add_column :tracked_jobs, :saved, :boolean, default: false, null: false
    add_column :tracked_jobs, :applied, :boolean, default: false, null: false
    add_column :tracked_jobs, :dismissed, :boolean, default: false, null: false
    add_index :tracked_jobs, [ :saved, :applied, :created_at ]
    add_index :tracked_jobs, :dismissed

    execute <<~SQL
      UPDATE tracked_jobs
      SET saved = status.saved, applied = status.applied, dismissed = status.dismissed
      FROM (
        SELECT tracked_job_id, BOOL_OR(saved) AS saved, BOOL_OR(applied) AS applied,
               BOOL_OR(dismissed) AS dismissed
        FROM user_tracked_jobs
        GROUP BY tracked_job_id
      ) AS status
      WHERE tracked_jobs.id = status.tracked_job_id
    SQL

    drop_table :user_tracked_jobs
  end
end
