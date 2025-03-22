class ArticleBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :content

  view :show do
    field :links do |article, _options|
      article.show_links
    end
  end

  view :index do
    field :links do |article, _options|
      current_user = _options[:context][:current_user]
      article.index_links(current_user)
    end
  end
end