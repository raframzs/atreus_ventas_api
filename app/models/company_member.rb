class CompanyMember < ApplicationRecord
  belongs_to :company
  belongs_to :user

  ROLES = %w[owner admin seller].freeze

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :company_id }
end
