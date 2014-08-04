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

ActiveRecord::Schema.define(version: 20140801124240) do

  create_table "cellular_numbers", force: true do |t|
    t.string   "user"
    t.float    "service_plan_price"
    t.float    "additional_local_airtime"
    t.float    "ld_and_roaming_charges"
    t.float    "data_voice_and_other"
    t.float    "other_frees"
    t.float    "gst"
    t.float    "subtotal"
    t.float    "total"
    t.integer  "client_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "clients", force: true do |t|
    t.integer  "client_number"
    t.integer  "bill_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "individual_details", force: true do |t|
    t.float    "total_onths_savings"
    t.float    "total"
    t.float    "service_plan_name"
    t.float    "additional_local_airtime"
    t.float    "long_distance_charges"
    t.float    "data_and_other_services"
    t.float    "value_addded_services"
    t.integer  "client_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
