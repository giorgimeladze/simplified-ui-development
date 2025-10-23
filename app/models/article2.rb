class Article2 < ApplicationRecord
  include HasHypermediaLinks
  include HasStateTransitions

  belongs_to :user
  validates :user, presence: true
  validates :title, :content, presence: true
  validates :rejection_feedback, length: { maximum: 1000 }, allow_blank: true
  has_many :comment2s, dependent: :destroy

  # Event sourcing methods
  def events
    @events ||= EventStore.get_events(id, 'Article2')
  end
  
  def load_from_events
    events.each do |event|
      case event.event_type
      when 'Article2Created'
        self.title = event.event_data['title']
        self.content = event.event_data['content']
        self.user_id = event.event_data['user_id']
        self.status = 'draft'
      when 'Article2Submitted'
        self.status = 'review'
      when 'Article2Rejected'
        self.status = 'rejected'
        self.rejection_feedback = event.event_data['rejection_feedback']
      when 'Article2ApprovedPrivate'
        self.status = 'privated'
      when 'Article2Published'
        self.status = 'published'
      when 'Article2Archived'
        self.status = 'archived'
      when 'Article2Updated'
        self.title = event.event_data['title']
        self.content = event.event_data['content']
      end
    end
  end

  # Status check methods
  def draft?
    status == 'draft'
  end

  def review?
    status == 'review'
  end

  def published?
    status == 'published'
  end

  def privated?
    status == 'privated'
  end

  def rejected?
    status == 'rejected'
  end

  def archived?
    status == 'archived'
  end

  # State transition validation methods
  def can_submit?
    draft?
  end

  def can_reject?
    review?
  end

  def can_approve_private?
    review?
  end

  def can_publish?
    review?
  end

  def can_archive?
    ['rejected', 'published', 'privated'].include?(status)
  end

  def can_resubmit?
    rejected?
  end

  def can_make_visible?
    privated?
  end

  def can_make_invisible?
    published?
  end

  def can_update?
    ['draft', 'rejected'].include?(status)
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
