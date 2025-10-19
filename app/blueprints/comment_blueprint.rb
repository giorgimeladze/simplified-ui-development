class CommentBlueprint < Blueprinter::Base
  identifier :id

  fields :text, :status, :user_id

  field :rejection_feedback,
        if: ->(_field_name, comment, options) do
          current_user = options[:context][:current_user]
          current_user&.admin? || current_user&.id == comment.user_id
        end

  view :show do
    field :links do |comment, _options|
      current_user = _options[:context][:current_user]
      comment.hypermedia_show_links(current_user)
    end
  end

  view :index do
    field :links do |comment, _options|
      current_user = _options[:context][:current_user]
      comment.hypermedia_index_links(current_user)
    end
  end
end