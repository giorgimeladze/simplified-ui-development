class Article < ApplicationRecord
  include AASM

  belongs_to :user

  validates :title, :content, presence: true

  aasm column: 'status' do
    state :draft, initial: true
    state :review, :private, :published, :rejected, :archived

    event :submit do
      transitions from: :draft, to: :review
    end

    event :reject do
      transitions from: :review, to: :rejected
    end

    event :approve do
      transitions from: :review, to: [:private, :published]
    end

    event :resubmit do
      transitions from: :rejected, to: :review
    end

    event :archive do
      transitions from: [:rejected, :published, :private], to: :archived
    end

    event :publish do
      transitions from: [:private, :review], to: :published
    end
  end
end
