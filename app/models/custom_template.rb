class CustomTemplate < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :template_data, presence: true

  # Default template structure organized by sections
  DEFAULT_TEMPLATE = {
    'Article' => {
      'index' => { 'title' => 'All Articles', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'new' => { 'title' => 'New Article', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'create' => { 'title' => 'Create Article', 'button_classes' => 'btn btn-outline-success btn-sm mx-1' },
      'show' => { 'title' => 'Show', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'submit' => { 'title' => 'Submit for Review', 'button_classes' => 'btn btn-outline-warning btn-sm mx-1' },
      'reject' => { 'title' => 'Submit Rejection', 'button_classes' => 'btn btn-danger btn-sm mx-1' },
      'approve_private' => { 'title' => 'Approve Private', 'button_classes' => 'btn btn-outline-info btn-sm mx-1' },
      'resubmit' => { 'title' => 'Resubmit', 'button_classes' => 'btn btn-outline-warning btn-sm mx-1' },
      'archive' => { 'title' => 'Archive', 'button_classes' => 'btn btn-outline-secondary btn-sm mx-1' },
      'publish' => { 'title' => 'Publish', 'button_classes' => 'btn btn-outline-success btn-sm mx-1' },
      'make_visible' => { 'title' => 'Make Visible', 'button_classes' => 'btn btn-outline-success btn-sm mx-1' },
      'make_invisible' => { 'title' => 'Make Invisible', 'button_classes' => 'btn btn-outline-warning btn-sm mx-1' }
    },
    'Comment' => {
      'index' => { 'title' => 'All Comments', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'new' => { 'title' => 'New Comment', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'create' => { 'title' => 'Add Comment', 'button_classes' => 'btn btn-outline-success btn-sm mx-1' },
      'show' => { 'title' => 'View', 'button_classes' => 'btn btn-outline-info btn-sm mx-1' },
      'edit' => { 'title' => 'Edit', 'button_classes' => 'btn btn-outline-warning btn-sm mx-1' },
      'approve' => { 'title' => 'Approve', 'button_classes' => 'btn btn-outline-success btn-sm mx-1' },
      'reject' => { 'title' => 'Submit Rejection', 'button_classes' => 'btn btn-danger btn-sm mx-1' },
      'delete' => { 'title' => 'Delete Comment', 'button_classes' => 'btn btn-outline-danger btn-sm mx-1' },
      'restore' => { 'title' => 'Restore', 'button_classes' => 'btn btn-outline-info btn-sm mx-1' }
    },
    'Navigation' => {
      'all_articles' => { 'title' => 'All Articles', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'my_articles' => { 'title' => 'My Articles', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'review_articles' => { 'title' => 'Review Articles', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'deleted_articles' => { 'title' => 'Deleted Articles', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'pending_comments' => { 'title' => 'Pending Comments', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'state_transitions' => { 'title' => 'State Transitions', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'sign_in' => { 'title' => 'Sign In', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'sign_up' => { 'title' => 'Sign Up', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'sign_out' => { 'title' => 'Sign Out', 'button_classes' => 'btn btn-outline-danger btn-sm mx-1' },
      'custom_template' => { 'title' => 'Customize UI', 'button_classes' => 'btn btn-outline-info btn-sm mx-1' }
    },
    'Article2' => {
      'index' => { 'title' => 'All Articles (Event)', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'new' => { 'title' => 'New Article (Event)', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'create' => { 'title' => 'Create Article (Event)', 'button_classes' => 'btn btn-outline-success btn-sm mx-1' },
      'show' => { 'title' => 'Show (Event)', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'submit' => { 'title' => 'Submit for Review (Event)', 'button_classes' => 'btn btn-outline-warning btn-sm mx-1' },
      'reject' => { 'title' => 'Submit Rejection (Event)', 'button_classes' => 'btn btn-danger btn-sm mx-1' },
      'approve_private' => { 'title' => 'Approve Private (Event)', 'button_classes' => 'btn btn-outline-info btn-sm mx-1' },
      'resubmit' => { 'title' => 'Resubmit (Event)', 'button_classes' => 'btn btn-outline-warning btn-sm mx-1' },
      'archive' => { 'title' => 'Archive (Event)', 'button_classes' => 'btn btn-outline-secondary btn-sm mx-1' },
      'publish' => { 'title' => 'Publish (Event)', 'button_classes' => 'btn btn-outline-success btn-sm mx-1' },
      'make_visible' => { 'title' => 'Make Visible (Event)', 'button_classes' => 'btn btn-outline-success btn-sm mx-1' },
      'make_invisible' => { 'title' => 'Make Invisible (Event)', 'button_classes' => 'btn btn-outline-warning btn-sm mx-1' }
    },
    'Comment2' => {
      'index' => { 'title' => 'All Comments (Event)', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'new' => { 'title' => 'New Comment (Event)', 'button_classes' => 'btn btn-outline-primary btn-sm mx-1' },
      'create' => { 'title' => 'Add Comment (Event)', 'button_classes' => 'btn btn-outline-success btn-sm mx-1' },
      'show' => { 'title' => 'View (Event)', 'button_classes' => 'btn btn-outline-info btn-sm mx-1' },
      'approve' => { 'title' => 'Approve (Event)', 'button_classes' => 'btn btn-outline-success btn-sm mx-1' },
      'reject' => { 'title' => 'Submit Rejection (Event)', 'button_classes' => 'btn btn-danger btn-sm mx-1' },
      'delete' => { 'title' => 'Delete Comment (Event)', 'button_classes' => 'btn btn-outline-danger btn-sm mx-1' },
      'restore' => { 'title' => 'Restore (Event)', 'button_classes' => 'btn btn-outline-info btn-sm mx-1' }
    }
  }.freeze

  def self.for_user(user)
    find_or_create_by(user: user) do |template|
      template.template_data = DEFAULT_TEMPLATE.deep_dup
    end
  end

  def get_customization(model_name, action_name)
    template_data.dig(model_name, action_name) || DEFAULT_TEMPLATE.dig(model_name, action_name) || {}
  end

  def reset_to_defaults
    update!(template_data: DEFAULT_TEMPLATE.deep_dup)
  end

  # Get actions for a specific section
  def get_section(section_name)
    template_data[section_name] || DEFAULT_TEMPLATE[section_name] || {}
  end

  # Update only a specific section
  def update_section(section_name, section_data)
    new_template_data = template_data.dup
    new_template_data[section_name] = section_data
    update(template_data: new_template_data)
  rescue StandardError
    false
  end

  # Reset only a specific section
  def reset_section(section_name)
    new_template_data = template_data.dup
    new_template_data[section_name] = DEFAULT_TEMPLATE[section_name].deep_dup
    update!(template_data: new_template_data)
  end

  # Get available sections
  def self.available_sections
    %w[Article Comment Navigation Article2 Comment2]
  end
end
