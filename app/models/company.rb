class Company < ApplicationRecord
  has_many :company_members, dependent: :destroy
  has_many :users, through: :company_members
  has_many :branches, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :sales, dependent: :destroy

  validates :name, presence: true
  validates :currency, presence: true
  validates :invoice_seq, numericality: { greater_than_or_equal_to: 0 }

  DEFAULT_WHATSAPP_TEMPLATE = "Hola {{cliente}}, te compartimos tu pedido {{factura}}:\n\n{{items}}\n\nTotal: {{total}}\n\n¡Gracias por tu compra!"

  after_destroy :cleanup_orphaned_users

  def next_invoice_number!
    with_lock do
      seq = invoice_seq + 1
      update_columns(invoice_seq: seq)
      "F-#{seq.to_s.rjust(5, '0')}"
    end
  end

  private

  def cleanup_orphaned_users
    User.where(super_admin: false).where.missing(:companies).destroy_all
  end
end
