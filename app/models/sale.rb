class Sale < ApplicationRecord
  STATUSES = %w[draft confirmed invoiced cancelled].freeze

  belongs_to :company
  belongs_to :branch,   optional: true
  belongs_to :customer, optional: true
  belongs_to :seller, class_name: "User", foreign_key: :seller_id
  has_many :sale_items, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validates :subtotal, :total, numericality: { greater_than_or_equal_to: 0 }

  def confirm!
    update!(status: "confirmed")
  end

  def invoice!
    raise "Solo se pueden facturar ventas confirmadas" unless status == "confirmed"

    number = company.next_invoice_number!
    update!(status: "invoiced", invoice_number: number, invoiced_at: Time.current)

    sale_items.each do |item|
      item.product&.decrement!(:stock, item.qty)
    end
  end

  def cancel!
    update!(status: "cancelled")
  end

  def mark_sent!(channel)
    case channel.to_s
    when "email"     then update_column(:sent_email_at, Time.current)
    when "whatsapp"  then update_column(:sent_whatsapp_at, Time.current)
    end
  end

  def recompute_totals!
    sub = sale_items.sum(:line_total)
    tot = [ sub - discount.to_f, 0 ].max
    update_columns(subtotal: sub, total: tot)
  end

  after_destroy :cleanup_r2_pdf

  private

  def cleanup_r2_pdf
    return unless shared_pdf_url.present? && R2_CLIENT
    key = "invoices/#{id}.pdf"
    R2_CLIENT.delete_object(bucket: R2_BUCKET, key: key)
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error "[R2] Error borrando PDF de venta #{id}: #{e.message}"
  end
end
