class Article2 < ApplicationRecord
  include AASM
  include HasHypermediaLinks
  include HasStateTransitions

  belongs_to :user
  validates :user, presence: true
  validates :title, :content, presence: true
  validates :rejection_feedback, length: { maximum: 1000 }, allow_blank: true
  has_many :comment2s, dependent: :destroy

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
      transitions from: [:rejected, :published, :privated], to: :archived
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
  scope :admin_visible, -> { where(status: ['published', 'privated', 'review']) }  

  def visible_comments(current_user)
    if current_user.admin?
      comment2s.where(status: ['approved', 'rejected'])
    else
      comment2s.where(status: 'approved').or(comment2s.where(user: current_user, status: 'rejected'))
    end
  end
end
