# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160217055311) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "intarray"

  create_table "active_admin_comments", force: true do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "admin_users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree

  create_table "claim_metrics", id: false, force: true do |t|
    t.integer "run_id"
    t.integer "claim_id"
    t.float   "cv"
    t.float   "ts"
    t.float   "min_ts"
    t.float   "max_ts"
    t.float   "number_supp_sources"
    t.float   "number_opp_sources"
    t.float   "total_sources"
    t.float   "number_distinct_value"
    t.float   "cv_global"
    t.float   "local_confidence_comparison"
    t.float   "ts_global"
    t.float   "ts_local"
    t.boolean "label"
  end

  add_index "claim_metrics", ["run_id", "claim_id"], name: "index_claim_metrics_on_run_id_and_claim_id", unique: true, using: :btree
  add_index "claim_metrics", ["run_id"], name: "index_claim_metrics_on_run_id", using: :btree

  create_table "claim_results", force: true do |t|
    t.integer "run_id"
    t.float   "confidence"
    t.boolean "is_true"
    t.float   "normalized"
    t.integer "bucket_id"
    t.integer "claim_id"
  end

  add_index "claim_results", ["bucket_id"], name: "index_claim_results_on_bucket_id", using: :btree
  add_index "claim_results", ["claim_id"], name: "index_claim_results_on_claim_id", using: :btree
  add_index "claim_results", ["confidence"], name: "index_claim_results_on_confidence", using: :btree
  add_index "claim_results", ["normalized"], name: "index_claim_results_on_normalized", using: :btree
  add_index "claim_results", ["run_id"], name: "index_claim_results_on_run_id", using: :btree

  create_table "dataset_rows", force: true do |t|
    t.integer "dataset_id"
    t.string  "object_key",                  null: false
    t.string  "property_key",                null: false
    t.string  "property_value",              null: false
    t.string  "source_id",      default: ""
    t.string  "timestamp",      default: ""
    t.integer "parent_id"
    t.integer "user_id",        default: 0,  null: false
  end

  add_index "dataset_rows", ["dataset_id"], name: "index_dataset_rows_on_dataset_id", using: :btree
  add_index "dataset_rows", ["object_key", "property_key", "property_value", "source_id", "timestamp", "user_id"], name: "index_dataset_rows_on_all", unique: true, using: :btree

  create_table "datasets", force: true do |t|
    t.integer  "user_id"
    t.string   "kind"
    t.string   "original_filename"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "s3_key",              limit: 1024
    t.string   "status"
    t.boolean  "multi",                            default: false
    t.string   "other_url"
    t.integer  "duplicate_rows"
    t.integer  "invalid_rows"
    t.integer  "allegated_by_run_id"
  end

  add_index "datasets", ["user_id"], name: "index_datasets_on_user_id", using: :btree

  create_table "datasets_runs", id: false, force: true do |t|
    t.integer "dataset_id"
    t.integer "run_id"
  end

  create_table "datasets_runsets", id: false, force: true do |t|
    t.integer "dataset_id"
    t.integer "runset_id"
  end

  add_index "datasets_runsets", ["dataset_id"], name: "index_datasets_runsets_on_dataset_id", using: :btree
  add_index "datasets_runsets", ["runset_id"], name: "index_datasets_runsets_on_runset_id", using: :btree

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "runs", force: true do |t|
    t.string   "algorithm"
    t.string   "general_config"
    t.string   "config"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.integer  "runset_id"
    t.float    "precision"
    t.float    "accuracy"
    t.float    "recall"
    t.float    "specificity"
    t.integer  "iterations"
    t.text     "last_error"
    t.integer  "allegates_run_id"
    t.integer  "allegates_claim_id"
    t.float    "allegates_value"
    t.text     "feature_scores"
    t.text     "decision_tree"
  end

  add_index "runs", ["runset_id"], name: "index_runs_on_runset_id", using: :btree

  create_table "runsets", force: true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "runsets", ["user_id"], name: "index_runsets_on_user_id", using: :btree

  create_table "source_results", force: true do |t|
    t.integer "run_id"
    t.string  "source_id"
    t.float   "trustworthiness"
    t.float   "normalized"
  end

  add_index "source_results", ["normalized"], name: "index_source_results_on_normalized", using: :btree
  add_index "source_results", ["run_id"], name: "index_source_results_on_run_id", using: :btree
  add_index "source_results", ["source_id"], name: "index_source_results_on_source_id", using: :btree
  add_index "source_results", ["trustworthiness"], name: "index_source_results_on_trustworthiness", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",   null: false
    t.string   "encrypted_password",     default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "authentication_token"
    t.boolean  "has_gui_access",         default: true
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
