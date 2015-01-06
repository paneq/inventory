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

ActiveRecord::Schema.define(version: 20150106132319) do

  create_table "changes", force: true do |t|
    t.string   "identifier",              null: false
    t.integer  "available_quantity",      null: false
    t.integer  "reserved_quantity",       null: false
    t.integer  "sold_quantity",           null: false
    t.integer  "available_quantity_diff", null: false
    t.integer  "reserved_quantity_diff",  null: false
    t.integer  "sold_quantity_diff",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "changes", ["identifier"], name: "index_changes_on_identifier"

  create_table "products", id: false, force: true do |t|
    t.string   "identifier",         null: false
    t.integer  "available_quantity", null: false
    t.integer  "reserved_quantity",  null: false
    t.integer  "sold_quantity",      null: false
    t.integer  "store_quantity",     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "products", ["identifier"], name: "index_products_on_identifier", unique: true

end
