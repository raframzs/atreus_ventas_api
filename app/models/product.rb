class Product < ApplicationRecord
  belongs_to :company
  belongs_to :branch, optional: true
  has_many :sale_items, dependent: :nullify

  validates :name, presence: true
  validates :sku,  presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(is_active: true) }

  after_destroy :delete_from_r2

  private

  def delete_from_r2
    return unless photo_url.present? && R2_CLIENT

    key = photo_url.sub(%r{\A#{Regexp.escape(R2_PUBLIC_URL)}/}, "")
    R2_CLIENT.delete_object(bucket: R2_BUCKET, key: key)
  rescue => e
    Rails.logger.warn "[R2] Could not delete #{photo_url}: #{e.message}"
  end
end
