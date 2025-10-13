# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Articles API', type: :request do
  
  # GET /articles
  path '/articles' do
    get 'Retrieves all published articles' do
      tags 'Articles'
      produces 'application/json'
      description 'Returns a collection of published articles with hypermedia controls (HATEOAS). Each article includes its current FSM state and available state transitions based on user permissions.'

      response '200', 'articles found' do
        schema '$ref' => '#/components/schemas/ArticlesCollection'
        
        run_test!
      end
    end
  end

  # GET /articles/my_articles
  path '/articles/my_articles' do
    get 'Retrieves current user\'s articles' do
      tags 'Articles'
      produces 'application/json'
      description 'Returns all articles created by the authenticated user, regardless of state.'
      security [bearer_auth: []]

      response '200', 'my articles found' do
        schema '$ref' => '#/components/schemas/ArticlesCollection'
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # GET /articles/articles_for_review
  path '/articles/articles_for_review' do
    get 'Retrieves articles pending review' do
      tags 'Articles'
      produces 'application/json'
      description 'Returns all articles in "review" state. Requires editor or admin role.'
      security [bearer_auth: []]

      response '200', 'articles for review found' do
        schema '$ref' => '#/components/schemas/ArticlesCollection'
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # GET /articles/deleted_articles
  path '/articles/deleted_articles' do
    get 'Retrieves archived articles' do
      tags 'Articles'
      produces 'application/json'
      description 'Returns archived articles. Admins see all archived articles, regular users see only their own.'
      security [bearer_auth: []]

      response '200', 'archived articles found' do
        schema '$ref' => '#/components/schemas/ArticlesCollection'
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # GET /articles/:id
  path '/articles/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Article ID'

    get 'Retrieves a specific article' do
      tags 'Articles'
      produces 'application/json'
      description 'Returns a single article with its comments and available actions based on current state and user permissions.'

      response '200', 'article found' do
        schema type: :object,
          properties: {
            article: { type: :string, description: 'Rendered HTML content with hypermedia links' }
          }
        run_test!
      end

      response '404', 'article not found' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # GET /articles/new
  path '/articles/new' do
    get 'Returns form for creating a new article' do
      tags 'Articles'
      produces 'application/json'
      description 'Returns an HTML form for creating a new article.'
      security [bearer_auth: []]

      response '200', 'form retrieved' do
        schema type: :object,
          properties: {
            form: { type: :string, description: 'Rendered HTML form' }
          }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # POST /articles
  path '/articles' do
    post 'Creates a new article' do
      tags 'Articles'
      consumes 'application/json'
      produces 'application/json'
      description 'Creates a new article in "draft" state. Requires authentication.'
      security [bearer_auth: []]

      parameter name: :article, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string, example: 'Introduction to FSM' },
          content: { type: :string, example: 'This article explains finite state machines...' }
        },
        required: ['title', 'content']
      }

      response '201', 'article created' do
        schema type: :object,
          properties: {
            success: { type: :boolean, example: true },
            article: { '$ref' => '#/components/schemas/Article' }
          }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '422', 'invalid request' do
        schema type: :object,
          properties: {
            success: { type: :boolean, example: false },
            errors: { type: :array, items: { type: :string } }
          }
        run_test!
      end
    end
  end

  # DELETE /articles/:id
  path '/articles/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Article ID'

    delete 'Deletes an article' do
      tags 'Articles'
      produces 'application/json'
      description 'Permanently deletes an article. Requires ownership or admin role.'
      security [bearer_auth: []]

      response '204', 'article deleted' do
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '404', 'article not found' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # FSM Transitions
  # POST /articles/:id/submit
  path '/articles/{id}/submit' do
    parameter name: :id, in: :path, type: :integer, description: 'Article ID'

    post 'Submit article for review (draft → review)' do
      tags 'Articles - FSM Transitions'
      produces 'application/json'
      description 'Transitions article from "draft" to "review" state. Requires article ownership.'
      security [bearer_auth: []]

      response '200', 'transition successful' do
        schema '$ref' => '#/components/schemas/TransitionSuccess'
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden - not allowed' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '422', 'invalid state transition' do
        schema '$ref' => '#/components/schemas/TransitionError'
        run_test!
      end
    end
  end

  # POST /articles/:id/publish
  path '/articles/{id}/publish' do
    parameter name: :id, in: :path, type: :integer, description: 'Article ID'

    post 'Publish article (review → published)' do
      tags 'Articles - FSM Transitions'
      produces 'application/json'
      description 'Transitions article from "review" to "published" state. Requires editor or admin role.'
      security [bearer_auth: []]

      response '200', 'transition successful' do
        schema '$ref' => '#/components/schemas/TransitionSuccess'
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '422', 'invalid state transition' do
        schema '$ref' => '#/components/schemas/TransitionError'
        run_test!
      end
    end
  end

  # POST /articles/:id/reject
  path '/articles/{id}/reject' do
    parameter name: :id, in: :path, type: :integer, description: 'Article ID'

    post 'Reject article (review → rejected)' do
      tags 'Articles - FSM Transitions'
      produces 'application/json'
      description 'Transitions article from "review" to "rejected" state. Requires editor or admin role.'
      security [bearer_auth: []]

      response '200', 'transition successful' do
        schema '$ref' => '#/components/schemas/TransitionSuccess'
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # POST /articles/:id/approve_private
  path '/articles/{id}/approve_private' do
    parameter name: :id, in: :path, type: :integer, description: 'Article ID'

    post 'Approve article as private (review → privated)' do
      tags 'Articles - FSM Transitions'
      produces 'application/json'
      description 'Transitions article from "review" to "privated" state. Requires editor or admin role.'
      security [bearer_auth: []]

      response '200', 'transition successful' do
        schema '$ref' => '#/components/schemas/TransitionSuccess'
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # POST /articles/:id/resubmit
  path '/articles/{id}/resubmit' do
    parameter name: :id, in: :path, type: :integer, description: 'Article ID'

    post 'Resubmit rejected article (rejected → review)' do
      tags 'Articles - FSM Transitions'
      produces 'application/json'
      description 'Transitions article from "rejected" back to "review" state. Requires article ownership.'
      security [bearer_auth: []]

      response '200', 'transition successful' do
        schema '$ref' => '#/components/schemas/TransitionSuccess'
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # POST /articles/:id/archive
  path '/articles/{id}/archive' do
    parameter name: :id, in: :path, type: :integer, description: 'Article ID'

    post 'Archive article' do
      tags 'Articles - FSM Transitions'
      produces 'application/json'
      description 'Transitions article to "archived" state from rejected, published, or privated. Requires admin role.'
      security [bearer_auth: []]

      response '200', 'transition successful' do
        schema '$ref' => '#/components/schemas/TransitionSuccess'
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # POST /articles/:id/make_visible
  path '/articles/{id}/make_visible' do
    parameter name: :id, in: :path, type: :integer, description: 'Article ID'

    post 'Make article visible (privated → published)' do
      tags 'Articles - FSM Transitions'
      produces 'application/json'
      description 'Transitions article from "privated" to "published" state. Requires admin role.'
      security [bearer_auth: []]

      response '200', 'transition successful' do
        schema '$ref' => '#/components/schemas/TransitionSuccess'
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # POST /articles/:id/make_invisible
  path '/articles/{id}/make_invisible' do
    parameter name: :id, in: :path, type: :integer, description: 'Article ID'

    post 'Make article invisible (published → privated)' do
      tags 'Articles - FSM Transitions'
      produces 'application/json'
      description 'Transitions article from "published" to "privated" state. Requires admin role.'
      security [bearer_auth: []]

      response '200', 'transition successful' do
        schema '$ref' => '#/components/schemas/TransitionSuccess'
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end
end
