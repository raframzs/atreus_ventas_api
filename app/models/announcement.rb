class Announcement < ApplicationRecord
  KINDS = %w[info tip warning update].freeze

  validates :body, presence: true, length: { maximum: 1000 }
  validates :kind, inclusion: { in: KINDS }

  scope :active, -> { where(active: true) }

  def self.current
    active.order(updated_at: :desc).first
  end
end
