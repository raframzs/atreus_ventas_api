# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_16_180000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "announcements", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "kind", default: "info", null: false
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "branches", force: :cascade do |t|
    t.string "city"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.string "email"
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_branches_on_company_id"
  end

  create_table "companies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "COP", null: false
    t.integer "invoice_seq", default: 0, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.text "whatsapp_template"
  end

  create_table "company_members", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.string "role", default: "seller", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["company_id", "user_id"], name: "index_company_members_on_company_id_and_user_id", unique: true
    t.index ["company_id"], name: "index_company_members_on_company_id"
    t.index ["user_id"], name: "index_company_members_on_user_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.bigint "company_id", null: false
    t.string "contact_name"
    t.string "contact_phone"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.text "notes"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_customers_on_company_id"
  end

  create_table "feedback_reports", force: :cascade do |t|
    t.jsonb "context_data", default: {}
    t.string "context_url"
    t.datetime "created_at", null: false
    t.text "message", null: false
    t.string "report_type", default: "other", null: false
    t.jsonb "screenshot_urls", default: []
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["report_type"], name: "index_feedback_reports_on_report_type"
    t.index ["status"], name: "index_feedback_reports_on_status"
    t.index ["user_id"], name: "index_feedback_reports_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "branch_id"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.string "photo_url"
    t.decimal "price", precision: 14, scale: 2, default: "0.0", null: false
    t.string "reference"
    t.string "sku", null: false
    t.integer "stock", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_products_on_branch_id"
    t.index ["company_id", "sku"], name: "index_products_on_company_id_and_sku"
    t.index ["company_id"], name: "index_products_on_company_id"
    t.index ["is_active"], name: "index_products_on_is_active"
  end

  create_table "sale_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "line_total", precision: 14, scale: 2, null: false
    t.string "name", null: false
    t.string "photo_url"
    t.bigint "product_id"
    t.integer "qty", null: false
    t.bigint "sale_id", null: false
    t.string "sku", null: false
    t.decimal "unit_price", precision: 14, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_sale_items_on_product_id"
    t.index ["sale_id"], name: "index_sale_items_on_sale_id"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "branch_id"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.decimal "discount", precision: 14, scale: 2, default: "0.0", null: false
    t.string "invoice_number"
    t.datetime "invoiced_at"
    t.text "notes"
    t.bigint "seller_id", null: false
    t.datetime "sent_email_at"
    t.datetime "sent_whatsapp_at"
    t.string "status", default: "draft", null: false
    t.decimal "subtotal", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_sales_on_branch_id"
    t.index ["company_id"], name: "index_sales_on_company_id"
    t.index ["customer_id"], name: "index_sales_on_customer_id"
    t.index ["invoice_number"], name: "index_sales_on_invoice_number", unique: true, where: "(invoice_number IS NOT NULL)"
    t.index ["seller_id"], name: "index_sales_on_seller_id"
    t.index ["status"], name: "index_sales_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "full_name", null: false
    t.string "password_digest", null: false
    t.boolean "super_admin", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "branches", "companies"
  add_foreign_key "company_members", "companies"
  add_foreign_key "company_members", "users"
  add_foreign_key "customers", "companies"
  add_foreign_key "feedback_reports", "users"
  add_foreign_key "products", "branches"
  add_foreign_key "products", "companies"
  add_foreign_key "sale_items", "products"
  add_foreign_key "sale_items", "sales"
  add_foreign_key "sales", "branches"
  add_foreign_key "sales", "companies"
  add_foreign_key "sales", "customers"
  add_foreign_key "sales", "users", column: "seller_id"
end
