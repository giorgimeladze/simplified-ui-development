# frozen_string_literal: true

class Article < ApplicationRecord
  include AASM
  include HasHypermediaLinks
  include HasStateTransitions

  belongs_to :user
  validates :user, presence: true
  validates :title, :content, presence: true
  validates :rejection_feedback, length: { maximum: 1000 }, allow_blank: true
  has_many :comments, dependent: :destroy

  aasm column: 'status' do
    state :draft, initial: true
    state :review, :privated, :published, :rejected, :archived

    event :submit do
      transitions from: :draft, to: :review
    end

    event :reject do
      transitions from: :review, to: :rejected
    end

    event :approve_private do
      transitions from: :review, to: :privated
    end

    event :resubmit do
      transitions from: :rejected, to: :review
    end

    event :archive do
      transitions from: %i[rejected published privated], to: :archived
    end

    event :publish do
      transitions from: :review, to: :published
    end

    event :make_visible do
      transitions from: :privated, to: :published
    end

    event :make_invisible do
      transitions from: :published, to: :privated
    end
  end

  scope :visible, -> { where(status: 'published') }
  scope :admin_visible, -> { where(status: %w[published privated review]) }

  def visible_comments(current_user)
    if current_user.nil?
      comments.where(status: 'approved')
    elsif current_user.admin?
      comments.where(status: %w[approved rejected])
    else
      comments.where(status: 'approved').or(comments.where(user: current_user, status: 'rejected'))
    end
  end

  def possible_status_events
    aasm.events.map(&:to_s)
  end
end
