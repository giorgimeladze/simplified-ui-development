class ArticleBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :content, :status, :rejection_feedback

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