# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Comments API', type: :request do
  # GET /comments/pending_comments
  path '/comments/pending_comments' do
    get 'Retrieves all pending comments' do
      tags 'Comments'
      produces 'application/json'
      description 'Returns all comments in "pending" state awaiting moderation. Requires moderator or admin role.'
      security [session_auth: []]

      response '200', 'pending comments found' do
        schema type: :object,
               required: %w[comments links],
               properties: {
                 comments: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/Comment' }
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

        let!(:user) { sign_in_user(role: :editor) }
        run_test!
      end
    end
  end

  # GET /comments/:id
  path '/comments/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    get 'Retrieves a specific comment' do
      tags 'Comments'
      produces 'application/json'
      description 'Returns a single comment with available actions based on current state and user permissions.'

      response '200', 'comment found' do
        schema type: :object,
               required: %w[comment links],
               properties: {
                 comment: {
                   type: :object,
                   required: %w[id text status user_id links],
                   properties: {
                     id: { type: :integer },
                     text: { type: :string },
                     status: { type: :string },
                     user_id: { type: :integer },
                     links: {
                       type: :array,
                       items: { '$ref' => '#/components/schemas/HypermediaLink' }
                     }
                   }
                 },
                 links: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/HypermediaLink' }
                 }
               }

        let(:comment_record) { create(:comment, status: 'approved') }
        let(:id) { comment_record.id }

        run_test!
      end

      response '404', 'comment not found' do
        schema '$ref' => '#/components/schemas/Error'
        before do
          sign_in_user(role: :editor)
        end

        let(:id) { 999_999 }

        run_test!
      end
    end
  end

  # POST /articles/:article_id/comments
  path '/articles/{article_id}/comments' do
    parameter name: :article_id, in: :path, type: :integer, description: 'Article ID'

    post 'Creates a new comment' do
      tags 'Comments'
      consumes 'application/json'
      produces 'application/json'
      description 'Creates a new comment in "pending" state. Requires authentication.'
      security [session_auth: []]

      parameter name: :comment, in: :body, schema: {
        type: :object,
        properties: {
          text: {
            type: :string,
            example: 'Great article! Very informative.',
            minLength: 1,
            maxLength: 250
          }
        },
        required: ['text']
      }

      response '201', 'comment created' do
        schema type: :object,
               required: ['comment'],
               properties: {
                 comment: {
                   type: :object,
                   required: %w[id text status user_id],
                   properties: {
                     id: { type: :integer },
                     text: { type: :string },
                     status: { type: :string, enum: ['pending'] },
                     user_id: { type: :integer }
                   }
                 }
               }

        let!(:user) { sign_in_user(role: :viewer) }
        let(:article) { create(:article, status: 'published') }
        let(:article_id) { article.id }
        let(:comment) { { text: 'Great article!' } }

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'

        let(:article) { create(:article, status: 'published') }
        let(:article_id) { article.id }
        let(:comment) { { text: 'Great article!' } }

        run_test!
      end

      response '404', 'article not found' do
        schema '$ref' => '#/components/schemas/Error'

        let!(:user) { sign_in_user(role: :viewer) }
        let(:article_id) { 999_999 }
        let(:comment) { { text: 'Great article!' } }

        run_test!
      end

      response '422', 'validation error' do
        schema type: :object,
               properties: {
                 errors: { type: :array, items: { type: :string } }
               }

        let!(:user) { sign_in_user(role: :viewer) }
        let(:article) { create(:article, status: 'published') }
        let(:article_id) { article.id }
        let(:comment) { { text: '' } }

        run_test!
      end
    end
  end

  # GET /comments/:id/edit
  path '/comments/{id}/edit' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    get 'Get comment edit form' do
      tags 'Comments'
      produces 'application/json'
      description 'Returns HTML form for editing comment. Only available for rejected comments.'
      security [session_auth: []]

      response '200', 'edit form retrieved' do
        schema type: :object,
               required: %w[comment links],
               properties: {
                 comment: {
                   type: :object,
                   required: %w[id text status user_id],
                   properties: {
                     id: { type: :integer },
                     text: { type: :string },
                     status: { type: :string, enum: %w[approved rejected] }, # adjust if you have more
                     user_id: { type: :integer }
                   }
                 },
                 links: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/HypermediaLink' }
                 }
               }

        let!(:user) { sign_in_user(role: :editor) }
        let(:comment_record) { create(:comment, status: 'rejected', user: user) }
        let(:id) { comment_record.id }

        run_test!
      end

      response '403', 'forbidden - not editable' do
        schema '$ref' => '#/components/schemas/Error'

        let!(:user) { sign_in_user(role: :editor) }
        let(:comment_record) { create(:comment, status: 'approved', user: user) } # not rejected => should be forbidden
        let(:id) { comment_record.id }

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'

        let(:comment_record) { create(:comment, status: 'rejected') }
        let(:id) { comment_record.id }

        run_test!
      end
    end
  end

  # PATCH /comments/:id
  path '/comments/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    patch 'Update comment' do
      tags 'Comments'
      consumes 'application/json'
      produces 'application/json'
      description 'Update comment text. Only allowed for rejected comments. Automatically moves to pending state.'
      security [session_auth: []]

      parameter name: :comment, in: :body, schema: {
        type: :object,
        properties: {
          text: { type: :string, example: 'Updated comment text' }
        },
        required: ['text']
      }

      response '200', 'comment updated' do
        schema type: :object,
               required: ['comment'],
               properties: {
                 comment: {
                   type: :object,
                   required: %w[id text status user_id],
                   properties: {
                     id: { type: :integer },
                     text: { type: :string },
                     status: { type: :string, enum: %w[approved rejected pending] },
                     user_id: { type: :integer }
                   }
                 },
                 links: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/HypermediaLink' }
                 }
               }

        let!(:user) { sign_in_user(role: :editor) }
        let(:comment_record) { create(:comment, status: 'rejected', user: user) }
        let(:id) { comment_record.id }
        let(:comment) { { text: 'Updated comment text' } }

        run_test!
      end

      response '403', 'forbidden - not editable' do
        schema '$ref' => '#/components/schemas/Error'

        let!(:user) { sign_in_user(role: :editor) }
        let(:comment_record) { create(:comment, status: 'approved', user: user) } # not rejected => forbidden
        let(:id) { comment_record.id }
        let(:comment) { { text: 'Trying to edit' } }

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'

        let(:comment_record) { create(:comment, status: 'rejected') }
        let(:id) { comment_record.id }
        let(:comment) { { text: 'Updated comment text' } }

        run_test!
      end

      response '422', 'validation error' do
        schema type: :object,
               properties: {
                 errors: { type: :array, items: { type: :string } }
               }

        let!(:user) { sign_in_user(role: :editor) }
        let(:comment_record) { create(:comment, status: 'rejected', user: user) }
        let(:id) { comment_record.id }
        let(:comment) { { text: '' } }

        run_test!
      end
    end
  end

  # FSM Transitions
  # POST /comments/:id/approve
  path '/comments/{id}/approve' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    post 'Approve comment (pending → approved)' do
      tags 'Comments - FSM Transitions'
      produces 'application/json'
      description 'Transitions comment from "pending" to "approved" state, making it publicly visible. Requires admin role.'
      security [session_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
               required: ['comment'],
               properties: {
                 comment: {
                   type: :object,
                   required: %w[id text status user_id],
                   properties: {
                     id: { type: :integer },
                     text: { type: :string },
                     status: { type: :string, enum: %w[pending approved rejected deleted] },
                     user_id: { type: :integer },
                     rejection_feedback: { type: :string, nullable: true },
                     links: {
                       type: :array,
                       items: { '$ref' => '#/components/schemas/HypermediaLink' }
                     }
                   }
                 },
                 links: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/HypermediaLink' }
                 }
               }

        let!(:user) { sign_in_user(role: :admin) }
        let(:article) { create(:article, status: 'published') }
        let(:comment_record) { create(:comment, article: article, status: 'pending') }
        let(:id) { comment_record.id }

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'

        let(:article) { create(:article, status: 'published') }
        let(:comment_record) { create(:comment, article: article, status: 'pending') }
        let(:id) { comment_record.id }

        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'

        let!(:user) { sign_in_user(role: :editor) }
        let(:article) { create(:article, status: 'published') }
        let(:comment_record) { create(:comment, article: article, status: 'pending') }
        let(:id) { comment_record.id }

        run_test!
      end
    end
  end

  # POST /comments/:id/reject
  path '/comments/{id}/reject' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    post 'Reject comment (pending → rejected)' do
      tags 'Comments - FSM Transitions'
      produces 'application/json'
      consumes 'application/json'
      description 'Transitions comment from "pending" to "rejected" state with feedback. Requires admin role.'
      security [session_auth: []]

      parameter name: :rejection_feedback, in: :body, schema: {
        type: :object,
        properties: {
          rejection_feedback: {
            type: :string,
            example: 'Please be more constructive in your feedback.',
            description: 'Detailed feedback explaining why the comment is being rejected'
          }
        },
        required: ['rejection_feedback']
      }

      response '200', 'transition successful' do
        schema type: :object,
               required: ['comment'],
               properties: {
                 comment: {
                   type: :object,
                   required: %w[id text status user_id],
                   properties: {
                     id: { type: :integer },
                     text: { type: :string },
                     status: { type: :string, enum: %w[pending approved rejected deleted] },
                     user_id: { type: :integer },
                     rejection_feedback: { type: :string, nullable: true },
                     links: {
                       type: :array,
                       items: { '$ref' => '#/components/schemas/HypermediaLink' }
                     }
                   }
                 },
                 links: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/HypermediaLink' }
                 }
               }

        let!(:user) { sign_in_user(role: :admin) }
        let(:article) { create(:article, status: 'published') }
        let(:comment_record) { create(:comment, article: article, status: 'pending') }
        let(:id) { comment_record.id }
        let(:rejection_feedback) { { rejection_feedback: 'Please be more constructive.' } }

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'

        let(:article) { create(:article, status: 'published') }
        let(:comment_record) { create(:comment, article: article, status: 'pending') }
        let(:id) { comment_record.id }
        let(:rejection_feedback) { { rejection_feedback: 'Feedback' } }

        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'

        let!(:user) { sign_in_user(role: :editor) }
        let(:article) { create(:article, status: 'published') }
        let(:comment_record) { create(:comment, article: article, status: 'pending') }
        let(:id) { comment_record.id }
        let(:rejection_feedback) { { rejection_feedback: 'Feedback' } }

        run_test!
      end
    end
  end

  # POST /comments/:id/delete
  path '/comments/{id}/delete' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    post 'Soft delete comment' do
      tags 'Comments - FSM Transitions'
      produces 'application/json'
      description 'Transitions comment to "deleted" state. Can be restored later. Requires comment ownership, admin, or editor role.'
      security [session_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
               required: ['comment'],
               properties: {
                 comment: {
                   type: :object,
                   required: %w[id text status user_id],
                   properties: {
                     id: { type: :integer },
                     text: { type: :string },
                     status: { type: :string, enum: %w[pending approved rejected deleted] },
                     user_id: { type: :integer },
                     rejection_feedback: { type: :string, nullable: true },
                     links: {
                       type: :array,
                       items: { '$ref' => '#/components/schemas/HypermediaLink' }
                     }
                   }
                 },
                 links: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/HypermediaLink' }
                 }
               }

        let!(:user) { sign_in_user(role: :admin) }
        let(:article) { create(:article, status: 'published') }
        let(:comment_record) { create(:comment, article: article, status: 'approved') }
        let(:id) { comment_record.id }

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'

        let(:article) { create(:article, status: 'published') }
        let(:comment_record) { create(:comment, article: article, status: 'approved') }
        let(:id) { comment_record.id }

        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'

        let!(:user) { sign_in_user(role: :viewer) }
        let(:article) { create(:article, status: 'published') }
        let(:comment_record) { create(:comment, article: article, status: 'approved') }
        let(:id) { comment_record.id }

        run_test!
      end
    end
  end

  # POST /comments/:id/restore
  path '/comments/{id}/restore' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    post 'Restore deleted comment' do
      tags 'Comments - FSM Transitions'
      produces 'application/json'
      description 'Transitions comment from "deleted" back to "pending" state. Requires admin or editor role.'
      security [session_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
               required: ['comment'],
               properties: {
                 comment: {
                   type: :object,
                   required: %w[id text status user_id],
                   properties: {
                     id: { type: :integer },
                     text: { type: :string },
                     status: { type: :string, enum: %w[pending approved rejected deleted] },
                     user_id: { type: :integer },
                     rejection_feedback: { type: :string, nullable: true },
                     links: {
                       type: :array,
                       items: { '$ref' => '#/components/schemas/HypermediaLink' }
                     }
                   }
                 },
                 links: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/HypermediaLink' }
                 }
               }

        let!(:user) { sign_in_user(role: :admin) }
        let(:article) { create(:article, status: 'published') }
        let(:comment_record) { create(:comment, article: article, status: 'deleted') }
        let(:id) { comment_record.id }

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'

        let(:article) { create(:article, status: 'published') }
        let(:comment_record) { create(:comment, article: article, status: 'deleted') }
        let(:id) { comment_record.id }

        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'

        let!(:user) { sign_in_user(role: :viewer) }
        let(:article) { create(:article, status: 'published') }
        let(:comment_record) { create(:comment, article: article, status: 'deleted') }
        let(:id) { comment_record.id }

        run_test!
      end
    end
  end
end
