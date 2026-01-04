# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Article2s API', type: :request do
  
  # GET /article2s
  path '/article2s' do
    get 'Retrieves all published articles' do
      tags 'Article2s'
      produces 'application/json'
      description 'Returns a collection of published articles with hypermedia controls (HATEOAS). Each article includes its current FSM state and available state transitions based on user permissions.'

      response '200', 'articles found' do
        schema type: :object,
          required: %w[article2s links],
          properties: {
            article2s: {
              type: :array,
              items: { type: :object } # or '$ref' => '#/components/schemas/Article2'
            },
            links: {
              type: :array,
              items: { '$ref' => '#/components/schemas/HypermediaLink' }
            }
          }

        let!(:user) { sign_in_user(role: :editor) }
        run_test!
      end
    end
  end

  # GET /article2s/my_article2s
  path '/article2s/my_article2s' do
    get 'Retrieves current user\'s articles' do
      tags 'Article2s'
      produces 'application/json'
      description 'Returns all articles created by the authenticated user, regardless of state.'
      security [bearer_auth: []]

      response '200', 'my articles found' do
        schema type: :object,
          required: %w[article2s links],
          properties: {
            article2s: {
              type: :array,
              items: { type: :object } # or '$ref' => '#/components/schemas/Article2'
            },
            links: {
              type: :array,
              items: { '$ref' => '#/components/schemas/HypermediaLink' }
            }
          }

        let!(:user) { sign_in_user(role: :editor) }

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # GET /article2s/article2s_for_review
  path '/article2s/article2s_for_review' do
    get 'Retrieves articles pending review' do
      tags 'Article2s'
      produces 'application/json'
      description 'Returns all articles in "review" or "draft" state. Requires admin role.'
      security [bearer_auth: []]

      response '200', 'articles for review found' do
        schema type: :object,
          required: %w[article2s links],
          properties: {
            article2s: {
              type: :array,
              items: { type: :object } # or '$ref' => '#/components/schemas/Article2'
            },
            links: {
              type: :array,
              items: { '$ref' => '#/components/schemas/HypermediaLink' }
            }
          }
      
        let!(:user) { sign_in_user(role: :admin) }
        run_test!
      end
      

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'

        before do
          sign_in_user(role: :editor)
        end
        run_test!
      end
    end
  end

  # GET /article2s/deleted_article2s
  path '/article2s/deleted_article2s' do
    get 'Retrieves archived articles' do
      tags 'Article2s'
      produces 'application/json'
      description 'Returns archived articles. Admins see all archived articles, regular users see only their own.'
      security [session_auth: []]

      response '200', 'archived articles found' do
        schema type: :object,
          required: %w[article2s links],
          properties: {
            article2s: {
              type: :array,
              items: { type: :object } # or '$ref' => '#/components/schemas/Article2' if you have it
            },
            links: {
              type: :array,
              items: { '$ref' => '#/components/schemas/HypermediaLink' }
            }
          }
      
        let!(:user) { sign_in_user(role: :editor) }
      
        run_test!
      end
      

      response '200', 'archived articles found' do
        schema type: :object,
          required: %w[article2s links],
          properties: {
            article2s: {
              type: :array,
              items: { '$ref' => '#/components/schemas/Article2' } # use your real schema, or :object if you don't have one
            },
            links: {
              type: :array,
              items: { '$ref' => '#/components/schemas/HypermediaLink' }
            }
          }
      
        let!(:user) { sign_in_user(role: :admin) }
      
        run_test!
      end      

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'

        before do
          sign_in_user(role: :viewer)
        end
        run_test!
      end
    end
  end

  # GET /article2s/:id
  path '/article2s/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'Article2 ID'

    get 'Retrieves a specific article (HAL-style with embedded comments)' do
      tags 'Article2s'
      produces 'application/json'
      description 'Returns a single article with HAL-style _embedded comments. Demonstrates hypermedia format with nested resources following HAL conventions.'

      response '200', 'article found' do
        schema type: :object,
          properties: {
            id: { type: :string, example: '550e8400-e29b-41d4-a716-446655440000' },
            title: { type: :string, example: 'Introduction to FSM' },
            content: { type: :string, example: 'This article explains...' },
            state: { 
              type: :string, 
              enum: ['draft', 'review', 'rejected', 'published', 'privated', 'archived'],
              example: 'published'
            },
            links: {
              type: :array,
              description: 'HATEOAS links for available actions',
              items: { '$ref' => '#/components/schemas/HypermediaLink' }
            },
            _embedded: {
              type: :object,
              description: 'HAL-style embedded resources',
              properties: {
                comment2s: {
                  type: :array,
                  description: 'Embedded comments for this article',
                  items: { '$ref' => '#/components/schemas/Comment' }
                }
              }
            }
          },
          example: {
            id: '550e8400-e29b-41d4-a716-446655440000',
            title: 'Getting Started with FSM',
            content: 'Finite State Machines simplify complex workflows...',
            state: 'published',
            links: [
              {
                rel: 'self',
                title: 'Show',
                method: 'GET',
                href: '/article2s/550e8400-e29b-41d4-a716-446655440000',
                button_classes: 'btn btn-outline-primary btn-sm mx-1'
              },
              {
                rel: 'transition:archive',
                title: 'Archive',
                method: 'POST',
                href: '/article2s/550e8400-e29b-41d4-a716-446655440000/archive',
                button_classes: 'btn btn-outline-secondary btn-sm mx-1'
              }
            ],
            _embedded: {
              comment2s: [
                {
                  id: '660e8400-e29b-41d4-a716-446655440000',
                  text: 'Great article!',
                  state: 'approved',
                  links: [
                    {
                      rel: 'self',
                      title: 'Show',
                      method: 'GET',
                      href: '/comment2s/660e8400-e29b-41d4-a716-446655440000'
                    }
                  ]
                }
              ]
            }
          }
          let(:user) { sign_in_user(role: :editor) }
          let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: user.id, state: 'published') }
          let(:id) { article.id }
        
          run_test!
      end

      response '404', 'article not found' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:id) { 'nonexistent-id' }
  
        before do
          sign_in_user(role: :viewer)
        end
  
        run_test!
      end
    end
  end

  # POST /article2s
  path '/article2s' do
    post 'Creates a new article' do
      tags 'Article2s'
      consumes 'application/json'
      produces 'application/json'
      description 'Creates a new article in "draft" state via event sourcing. Requires authentication.'
      security [session_auth: []]

      parameter name: :article2, in: :body, schema: {
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
            success: { type: :boolean, example: true }
          },
          required: ['success']
  
        before do
          sign_in_user(role: :editor)
        end
        let(:article2) { { title: 'Intro', content: 'Hello' } }
  
        run_test!
      end
  
      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:article2) { { title: 'Intro', content: 'Hello' } }
  
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
      
        before do
          sign_in_user(role: :viewer)
        end
      
        let(:article2) { { title: 'Intro', content: 'Hello' } }
      
        run_test!
      end
    end
  end

  # FSM Transitions
  # POST /article2s/:id/submit
  path '/article2s/{id}/submit' do
    parameter name: :id, in: :path, type: :string, description: 'Article2 ID'

    post 'Submit article for review (draft → review)' do
      tags 'Article2s - FSM Transitions'
      produces 'application/json'
      description 'Transitions article from "draft" to "review" state via event sourcing. Requires article ownership.'
      security [session_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
          required: %w[article2_id],
          properties: {
            article2_id: { type: :string, format: :uuid }
          }
      
        let(:user) { sign_in_user(role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: user.id,
            state: 'draft'
          )
        end
        let(:id) { article.id }
      
        run_test!
      end
      

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:other_user) { create(:user, role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: other_user.id,
            state: 'draft'
          )
        end
        let(:id) { article.id }
  
        run_test!
      end

      response '403', 'forbidden - not allowed' do
        schema '$ref' => '#/components/schemas/Error'

        before do
          sign_in_user(role: :editor)
        end
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 999, state: 'draft') } # different owner
        let(:id) { article.id }
  
        run_test!
      end
    end
  end

  # POST /article2s/:id/publish
  path '/article2s/{id}/publish' do
    parameter name: :id, in: :path, type: :string, description: 'Article2 ID'

    post 'Publish article (review → published)' do
      tags 'Article2s - FSM Transitions'
      produces 'application/json'
      description 'Transitions article from "review" to "published" state via event sourcing. Requires admin role.'
      security [session_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
          required: %w[article2_id],
          properties: {
            article2_id: { type: :string, format: :uuid }
          }
      
        let!(:user) { sign_in_user(role: :admin) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: user.id,
            state: 'review'
          )
        end
        let(:id) { article.id }
      
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:other_user) { create(:user, role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: other_user.id,
            state: 'review'
          )
        end
        let(:id) { article.id }
  
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
  
        before do
          sign_in_user(role: :viewer)
        end
        let(:other_user) { create(:user, role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: other_user.id,
            state: 'review'
          )
        end
        let(:id) { article.id }
  
        run_test!
      end
    end
  end

  # POST /article2s/:id/reject
  path '/article2s/{id}/reject' do
    parameter name: :id, in: :path, type: :string, description: 'Article2 ID'

    post 'Reject article (review → rejected)' do
      tags 'Article2s - FSM Transitions'
      produces 'application/json'
      consumes 'application/json'
      description 'Transitions article from "review" to "rejected" state with feedback via event sourcing. Requires admin role.'
      security [session_auth: []]

      parameter name: :rejection_feedback, in: :body, schema: {
        type: :object,
        properties: {
          rejection_feedback: { type: :string }
        },
        required: ['rejection_feedback']
      }

      response '200', 'transition successful' do
        schema type: :object,
          required: %w[article2_id],
          properties: {
            article2_id: { type: :string, format: :uuid }
          }
      
        let!(:user) { sign_in_user(role: :admin) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: user.id,
            state: 'review'
          )
        end
        let(:id) { article.id }
        let(:rejection_feedback) { { rejection_feedback: 'Needs improvements.' } }
      
        run_test!
      end
      

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:other_user) { create(:user, role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: other_user.id,
            state: 'review'
          )
        end
        let(:id) { article.id }
        let(:rejection_feedback) { { rejection_feedback: 'Needs improvements.' } }
  
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
  
        before do
          sign_in_user(role: :editor)
        end
        let(:other_user) { create(:user, role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: other_user.id,
            state: 'review'
          )
        end
        let(:id) { article.id }
        let(:rejection_feedback) { { rejection_feedback: 'Needs improvements.' } }
  
        run_test!
      end
    end
  end

  # POST /article2s/:id/approve_private
  path '/article2s/{id}/approve_private' do
    parameter name: :id, in: :path, type: :string, description: 'Article2 ID'

    post 'Approve article as private (review → privated)' do
      tags 'Article2s - FSM Transitions'
      produces 'application/json'
      description 'Transitions article from "review" to "privated" state via event sourcing. Requires editor or admin role.'
      security [session_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
          required: %w[article2_id],
          properties: {
            article2_id: { type: :string, format: :uuid }
          }
      
        let(:user) { sign_in_user(role: :admin) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: user.id,
            state: 'review'
          )
        end
        let(:id) { article.id }
      
        run_test!
      end
      

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:other_user) { create(:user, role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: other_user.id,
            state: 'review'
          )
        end
        let(:id) { article.id }
  
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
  
        before do
          sign_in_user(role: :viewer)
        end
        let(:other_user) { create(:user, role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: other_user.id,
            state: 'review'
          )
        end
        let(:id) { article.id }
  
        run_test!
      end
    end
  end

  # POST /article2s/:id/resubmit
  path '/article2s/{id}/resubmit' do
    parameter name: :id, in: :path, type: :string, description: 'Article2 ID'

    post 'Resubmit rejected article (rejected → review)' do
      tags 'Article2s - FSM Transitions'
      produces 'application/json'
      description 'Transitions article from "rejected" back to "review" state via event sourcing. Requires article ownership.'
      security [session_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
          required: %w[article2_id],
          properties: {
            article2_id: { type: :string, format: :uuid }
          }
      
        let(:user) { sign_in_user(role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: user.id,
            state: 'rejected'
          )
        end
        let(:id) { article.id }
      
        run_test!
      end
      

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:other_user) { create(:user, role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: other_user.id,
            state: 'rejected'
          )
        end
        let(:id) { article.id }
  
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
  
        before do
          sign_in_user(role: :editor)
        end
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 999, state: 'rejected') } # different owner
        let(:id) { article.id }
  
        run_test!
      end
    end
  end

  # POST /article2s/:id/archive
  path '/article2s/{id}/archive' do
    parameter name: :id, in: :path, type: :string, description: 'Article2 ID'

    post 'Archive article' do
      tags 'Article2s - FSM Transitions'
      produces 'application/json'
      description 'Transitions article to "archived" state from rejected, published, or privated via event sourcing. Requires admin role.'
      security [session_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
          required: %w[article2_id],
          properties: {
            article2_id: { type: :string, format: :uuid }
          }
      
        let!(:user) { sign_in_user(role: :admin) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: user.id,
            state: 'published'
          )
        end
        let(:id) { article.id }
      
        run_test!
      end
      

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:other_user) { create(:user, role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: other_user.id,
            state: 'published'
          )
        end
        let(:id) { article.id }
  
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
  
        before do
          sign_in_user(role: :editor)
        end
        let(:other_user) { create(:user, role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: other_user.id,
            state: 'published'
          )
        end
        let(:id) { article.id }
  
        run_test!
      end
    end
  end

  # POST /article2s/:id/make_visible
  path '/article2s/{id}/make_visible' do
    parameter name: :id, in: :path, type: :string, description: 'Article2 ID'

    post 'Make article visible (privated → published)' do
      tags 'Article2s - FSM Transitions'
      produces 'application/json'
      description 'Transitions article from "privated" to "published" state via event sourcing. Requires editor or admin role.'
      security [session_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
          required: %w[article2_id],
          properties: {
            article2_id: { type: :string, format: :uuid }
          }
      
        let!(:user) { sign_in_user(role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: user.id,
            state: 'privated'
          )
        end
        let(:id) { article.id }
      
        run_test!
      end
      

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:other_user) { create(:user, role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: other_user.id,
            state: 'privated'
          )
        end
        let(:id) { article.id }
  
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
  
        before do
          sign_in_user(role: :viewer)
        end
        let(:other_user) { create(:user, role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: other_user.id,
            state: 'privated'
          )
        end
        let(:id) { article.id }
  
        run_test!
      end
    end
  end

  # POST /article2s/:id/make_invisible
  path '/article2s/{id}/make_invisible' do
    parameter name: :id, in: :path, type: :string, description: 'Article2 ID'

    post 'Make article invisible (published → privated)' do
      tags 'Article2s - FSM Transitions'
      produces 'application/json'
      description 'Transitions article from "published" to "privated" state via event sourcing. Requires editor or admin role.'
      security [session_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
          required: %w[article2_id],
          properties: {
            article2_id: { type: :string, format: :uuid }
          }
      
        let(:user) { sign_in_user(role: :admin) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: user.id,
            state: 'published'
          )
        end
        let(:id) { article.id }
      
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:other_user) { create(:user, role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: other_user.id,
            state: 'published'
          )
        end
        let(:id) { article.id }
  
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
  
        before do
          sign_in_user(role: :viewer)
        end
        let(:other_user) { create(:user, role: :editor) }
        let(:article) do
          Article2ReadModel.create!(
            id: SecureRandom.uuid,
            title: 'Test',
            content: 'Content',
            author_id: other_user.id,
            state: 'published'
          )
        end
        let(:id) { article.id }
  
        run_test!
      end
    end
  end
end

