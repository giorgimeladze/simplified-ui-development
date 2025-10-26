class Comment2 < ApplicationRecord
  include HasHypermediaLinks
  include HasStateTransitions

  belongs_to :article2
  belongs_to :user  # created_by

  validates :text, presence: true, length: { minimum: 1, maximum: 250 }
  validates :user, :article2, presence: true
  validates :rejection_feedback, length: { maximum: 1000 }, allow_blank: true

  # Scopes
  scope :visible, -> { where(status: 'approved') }
  scope :awaiting_moderation, -> { where(status: 'pending') }
  scope :not_deleted, -> { where.not(status: 'deleted') }
  

  # Event sourcing methods
  def events
    @events ||= EventStore.get_events(id, 'Comment2')
  end
  
  def load_from_events
    events.each do |event|
      case event.event_type
      when 'Comment2Created'
        self.text = event.event_data['text']
        self.article2_id = event.event_data['article2_id']
        self.user_id = event.event_data['user_id']
        self.status = 'pending'
      when 'Comment2Approved'
        self.status = 'approved'
      when 'Comment2Rejected'
        self.status = 'rejected'
        self.rejection_feedback = event.event_data['rejection_feedback']
      when 'Comment2Deleted'
        self.status = 'deleted'
      when 'Comment2Restored'
        self.status = 'pending'
      when 'Comment2Updated'
        self.text = event.event_data['text']
        self.status = event.event_data['status']
      end
    end
  end

  def possible_status_events
    events = []
    events << 'approve' if status == 'pending'
    events << 'reject' if status == 'pending'
    events << 'delete' if ['pending', 'approved', 'rejected'].include?(status)
    events << 'restore' if status == 'deleted'
    events
  end

  ['pending', 'approved', 'rejected', 'pending', 'deleted'].each do |status|
    define_method("#{status}?") do
      self.status == status
    end
  end
end
