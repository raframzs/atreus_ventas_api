class SaleItem < ApplicationRecord
  belongs_to :sale
  belongs_to :product, optional: true

  validates :name, :sku, presence: true
  validates :qty, numericality: { greater_than: 0 }
  validates :unit_price, :line_total, numericality: { greater_than_or_equal_to: 0 }

  before_validation :compute_line_total

  private

  def compute_line_total
    self.line_total = qty.to_i * unit_price.to_f if qty && unit_price
  end
end
