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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130412184133) do

  create_table "cargo_types", :force => true do |t|
    t.integer  "remote_id"
    t.string   "maintype"
    t.string   "subtype"
    t.string   "subsubtype"
    t.string   "subsubsubtype"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "charges", :force => true do |t|
    t.integer  "port_id"
    t.text     "code"
    t.string   "name"
    t.string   "key"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "row_order"
  end

  create_table "companies", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "configurations", :force => true do |t|
    t.string   "company_name"
    t.string   "company_address1"
    t.string   "company_address2"
    t.string   "bank_name"
    t.string   "bank_address1"
    t.string   "bank_address2"
    t.string   "swift_code"
    t.string   "bsb_number"
    t.string   "ac_number"
    t.string   "ac_name"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "currencies", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.string   "symbol"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "disbursment_revisions", :force => true do |t|
    t.integer  "disbursment_id"
    t.hstore   "data"
    t.hstore   "fields"
    t.hstore   "descriptions"
    t.hstore   "values"
    t.hstore   "values_with_tax"
    t.hstore   "codes"
    t.boolean  "tax_exempt",      :default => false
    t.integer  "number"
    t.integer  "cargo_qty",       :default => 0
    t.integer  "days_alongside",  :default => 0
    t.integer  "loadtime",        :default => 0
    t.integer  "tugs_in",         :default => 0
    t.integer  "tugs_out",        :default => 0
    t.string   "reference"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.integer  "cargo_type_id"
  end

  create_table "disbursments", :force => true do |t|
    t.integer  "port_id"
    t.integer  "vessel_id"
    t.integer  "company_id"
    t.integer  "status_cd",      :default => 0
    t.string   "publication_id"
    t.boolean  "tbn",            :default => false
    t.decimal  "grt"
    t.decimal  "nrt"
    t.decimal  "dwt"
    t.decimal  "loa"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.integer  "terminal_id"
  end

  create_table "estimate_revisions", :force => true do |t|
    t.integer  "estimate_id"
    t.hstore   "data"
    t.hstore   "fields"
    t.hstore   "descriptions"
    t.hstore   "values"
    t.hstore   "values_with_tax"
    t.hstore   "codes"
    t.integer  "number"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "cargo_qty",       :default => 0
    t.integer  "days_alongside",  :default => 0
    t.integer  "loadtime",        :default => 0
    t.integer  "tugs_in",         :default => 0
    t.integer  "tugs_out",        :default => 0
  end

  create_table "estimates", :force => true do |t|
    t.integer  "port_id"
    t.integer  "vessel_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "status_cd",      :default => 0
    t.string   "publication_id"
  end

  create_table "ports", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "currency_id"
    t.integer  "tax_id"
  end

  create_table "services", :force => true do |t|
    t.integer  "port_id"
    t.integer  "terminal_id"
    t.text     "code"
    t.string   "item"
    t.string   "key"
    t.integer  "row_order"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "tariffs", :force => true do |t|
    t.string   "name"
    t.string   "document"
    t.integer  "user_id"
    t.integer  "port_id"
    t.integer  "terminal_id"
    t.date     "validity_start"
    t.date     "validity_end"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "taxes", :force => true do |t|
    t.string   "name"
    t.decimal  "rate"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "code"
  end

  create_table "terminals", :force => true do |t|
    t.integer  "port_id"
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "uid"
    t.string   "provider"
    t.string   "first_name"
    t.string   "last_name"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "vessels", :force => true do |t|
    t.string   "name"
    t.decimal  "loa"
    t.decimal  "grt"
    t.decimal  "nrt"
    t.decimal  "dwt"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
