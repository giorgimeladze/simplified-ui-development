class Comment < ApplicationRecord
  include AASM
  include HasHypermediaLinks

  belongs_to :article
  belongs_to :user  # created_by

  validates :text, presence: true, length: { minimum: 1, maximum: 250 }
  validates :user, :article, presence: true

  # FSM Definition
  aasm column: 'status' do
    state :pending, initial: true
    state :approved
    state :deleted

    event :approve do
      transitions from: :pending, to: :approved
    end

    event :delete do
      transitions from: [:pending, :approved], to: :deleted
    end

    event :restore do
      transitions from: :deleted, to: :pending
    end
  end

  # Scopes
  scope :visible, -> { where(status: 'approved') }
  scope :awaiting_moderation, -> { where(status: 'pending') }
  scope :not_deleted, -> { where.not(status: 'deleted') }
end
