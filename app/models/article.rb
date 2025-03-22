class Article < ApplicationRecord
  include AASM
  include ArticleLinks

  belongs_to :user

  validates :title, :content, presence: true

  aasm column: 'status' do
    state :draft, initial: true
    state :review, :privated, :published, :rejected, :archived

    event :submit do
      transitions from: :draft, to: :review
    end

    event :reject do
      transitions from: :review, to: :rejected
    end

    event :approve do
      transitions from: :review, to: [:privated, :published]
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
end
