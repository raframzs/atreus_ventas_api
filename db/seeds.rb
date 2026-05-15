# Idempotente — se puede correr múltiples veces sin duplicar datos.

# --- Super-admin ------------------------------------------------------------
admin = User.find_or_initialize_by(username: "admin")
if admin.new_record?
  admin.assign_attributes(
    full_name:             "Administrador",
    password:              ENV.fetch("ADMIN_PASSWORD", "Admin123!"),
    password_confirmation: ENV.fetch("ADMIN_PASSWORD", "Admin123!"),
    super_admin:           true
  )
  admin.save!
  puts "  Created super-admin: admin / Admin123!"
else
  admin.update!(super_admin: true) unless admin.super_admin?
  puts "  Super-admin already exists"
end

# --- Usuario demo -----------------------------------------------------------
demo = User.find_or_initialize_by(username: "demo")
if demo.new_record?
  demo.assign_attributes(
    full_name:             "Usuario Demo",
    email:                 "demo@atreus.app",
    password:              "demo1234",
    password_confirmation: "demo1234"
  )
  demo.save!
  puts "  Created user: demo / demo1234"
else
  puts "  User demo already exists"
end

# En producción solo creamos el usuario demo y salimos.
# Los datos de empresa/catálogo se crean desde la UI.
exit if Rails.env.production?

# --- Datos de desarrollo ----------------------------------------------------
company = Company.find_or_create_by!(name: "Atreus Demo") do |c|
  c.whatsapp_template = Company::DEFAULT_WHATSAPP_TEMPLATE
end
CompanyMember.find_or_create_by!(company: company, user: demo) { |m| m.role = "owner" }

branch_ll = company.branches.find_or_create_by!(name: "LadyLover") { |b| b.city = "Bogotá" }
branch_al = company.branches.find_or_create_by!(name: "AnyLady")   { |b| b.city = "Medellín" }

# Productos de ejemplo
[
  { branch: branch_ll, sku: "LL-001", name: "Bolso Cuero Café",    price: 85_000, stock: 20 },
  { branch: branch_ll, sku: "LL-002", name: "Cartera Mini Rosa",   price: 65_000, stock: 15 },
  { branch: branch_ll, sku: "LL-003", name: "Morral Ejecutivo",    price: 120_000, stock: 8 },
  { branch: branch_al, sku: "AL-001", name: "Bolso Tela Rayas",    price: 55_000, stock: 25 },
  { branch: branch_al, sku: "AL-002", name: "Riñonera Deportiva",  price: 45_000, stock: 30 },
].each do |attrs|
  company.products.find_or_create_by!(sku: attrs[:sku]) do |p|
    p.branch    = attrs[:branch]
    p.name      = attrs[:name]
    p.price     = attrs[:price]
    p.stock     = attrs[:stock]
    p.is_active = true
  end
end

# Clientes de ejemplo
[
  { name: "Ana Martínez",   phone: "573001111111", city: "Bogotá" },
  { name: "Lucía Ramírez",  phone: "573002222222", city: "Medellín" },
  { name: "Tienda El Sol",  phone: "573003333333", city: "Cali" },
].each do |attrs|
  company.customers.find_or_create_by!(name: attrs[:name]) do |c|
    c.phone = attrs[:phone]
    c.city  = attrs[:city]
  end
end

puts "  Seed dev: company='#{company.name}', #{company.branches.count} sucursales, #{company.products.count} productos, #{company.customers.count} clientes"
