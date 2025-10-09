class CommentBlueprint < Blueprinter::Base
  identifier :id

  fields :text, :status

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