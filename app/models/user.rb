class User < ApplicationRecord
  has_secure_password

  has_many :company_members, dependent: :destroy
  has_many :companies, through: :company_members
  has_many :sales, foreign_key: :seller_id, dependent: :nullify
  has_many :feedback_reports, dependent: :destroy

  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-z0-9_]+\z/, message: "solo letras minúsculas, números y guion bajo" }
  validates :full_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  before_save { username.downcase! }
end
