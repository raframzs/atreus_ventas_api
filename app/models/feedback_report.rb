class FeedbackReport < ApplicationRecord
  belongs_to :user

  enum :report_type, { bug: "bug", suggestion: "suggestion", other: "other" }, default: "other"
  enum :status, { pending: "pending", reviewed: "reviewed" }, default: "pending"

  validates :message, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :report_type, inclusion: { in: report_types.keys }

  scope :recent, -> { order(created_at: :desc) }
end
