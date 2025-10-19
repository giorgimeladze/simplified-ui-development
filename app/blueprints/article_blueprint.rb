class ArticleBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :content, :status, :user_id

  field :rejection_feedback,
        if: ->(_field_name, article, options) do
          current_user = options[:context][:current_user]
          current_user&.admin? || current_user&.id == article.user_id
        end

  view :show do
    field :links do |article, _options|
      current_user = _options[:context][:current_user]
      article.hypermedia_show_links(current_user)
    end
  end

  view :index do
    field :links do |article, _options|
      current_user = _options[:context][:current_user]
      article.hypermedia_index_links(current_user)
    end
  end
end