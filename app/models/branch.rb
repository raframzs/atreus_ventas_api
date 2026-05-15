class Branch < ApplicationRecord
  belongs_to :company
  has_many :products, dependent: :nullify
  has_many :sales, dependent: :nullify

  validates :name, presence: true
end
