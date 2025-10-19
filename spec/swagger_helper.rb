# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.json' => {
      openapi: '3.0.1',
      info: {
        title: 'FSM + HATEOAS Rails API',
        version: 'v1',
        description: 'API demonstrating Finite State Machines with HATEOAS hypermedia controls for simplified UI development. This API provides self-descriptive resources where available actions are determined by the current state and user permissions.',
        contact: {
          name: 'API Support',
          url: 'https://github.com/yourusername/simplified-ui-development'
        }
      },
      paths: {},
      servers: [
        {
          url: 'http://{defaultHost}',
          variables: {
            defaultHost: {
              default: 'localhost:3000'
            }
          }
        }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT',
            description: 'Authentication token required for protected endpoints'
          }
        },
        schemas: {
          # Hypermedia Link Schema
          HypermediaLink: {
            type: :object,
            properties: {
              rel: { 
                type: :string, 
                description: 'Link relation type (RFC 5988)',
                example: 'transition:publish'
              },
              title: { 
                type: :string, 
                description: 'Human-readable action label',
                example: 'Publish Article'
              },
              method: { 
                type: :string, 
                enum: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
                description: 'HTTP method',
                example: 'POST'
              },
              href: { 
                type: :string, 
                description: 'URL endpoint',
                example: '/articles/1/publish'
              },
              button_classes: {
                type: :string,
                description: 'CSS classes for UI rendering',
                example: 'btn btn-success',
                nullable: true
              },
              confirm: {
                type: :string,
                description: 'Confirmation message for destructive actions',
                example: 'Are you sure?',
                nullable: true
              }
            },
            required: ['rel', 'title', 'method', 'href']
          },

          # Article Schema
          Article: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              title: { type: :string, example: 'Introduction to Rails' },
              content: { type: :string, example: 'This is a comprehensive guide to Ruby on Rails...' },
              status: { 
                type: :string, 
                enum: ['draft', 'review', 'rejected', 'published', 'privated', 'archived'],
                example: 'published',
                description: 'Current FSM state of the article'
              },
              user_id: { type: :integer, example: 1, description: 'ID of the author' },
              rejection_feedback: { 
                type: :string, 
                example: 'Please improve the introduction and add more examples.',
                description: 'Feedback provided when article was rejected (only visible to admin and author)',
                nullable: true
              },
              created_at: { type: :string, format: 'date-time', example: '2024-10-09T12:00:00Z' },
              updated_at: { type: :string, format: 'date-time', example: '2024-10-09T14:30:00Z' },
              links: {
                type: :array,
                description: 'HATEOAS hypermedia controls - available actions based on current state',
                items: { '$ref' => '#/components/schemas/HypermediaLink' }
              }
            },
            required: ['id', 'title', 'content', 'status', 'links']
          },

          # Articles Collection Schema
          ArticlesCollection: {
            type: :object,
            properties: {
              articles: {
                type: :array,
                items: { '$ref' => '#/components/schemas/Article' }
              },
              links: {
                type: :array,
                description: 'Global navigation links',
                items: { '$ref' => '#/components/schemas/HypermediaLink' }
              }
            },
            required: ['articles', 'links']
          },

          # Comment Schema
          Comment: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              text: { type: :string, example: 'Great article! Very informative.' },
              status: { 
                type: :string, 
                enum: ['pending', 'approved', 'rejected', 'deleted'],
                example: 'approved',
                description: 'Current FSM state of the comment'
              },
              article_id: { type: :integer, example: 5, description: 'ID of the parent article' },
              user_id: { type: :integer, example: 3, description: 'ID of the comment author' },
              rejection_feedback: { 
                type: :string, 
                example: 'Please be more constructive in your feedback.',
                description: 'Feedback provided when comment was rejected (only visible to admin and author)',
                nullable: true
              },
              created_at: { type: :string, format: 'date-time', example: '2024-10-09T13:45:00Z' },
              updated_at: { type: :string, format: 'date-time', example: '2024-10-09T13:45:00Z' },
              links: {
                type: :array,
                description: 'HATEOAS hypermedia controls - available actions based on current state',
                items: { '$ref' => '#/components/schemas/HypermediaLink' }
              }
            },
            required: ['id', 'text', 'status', 'links']
          },

          # State Transition Schema
          StateTransition: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1, description: 'Transition log entry ID' },
              transitionable_type: { 
                type: :string, 
                enum: ['Article', 'Comment'],
                example: 'Article',
                description: 'Type of resource that transitioned'
              },
              transitionable_id: { 
                type: :integer, 
                example: 5,
                description: 'ID of the resource that transitioned'
              },
              from_state: { 
                type: :string, 
                example: 'draft',
                description: 'State before transition'
              },
              to_state: { 
                type: :string, 
                example: 'review',
                description: 'State after transition'
              },
              event: { 
                type: :string, 
                example: 'submit',
                description: 'FSM event that triggered the transition'
              },
              user_id: { 
                type: :integer, 
                example: 1,
                description: 'ID of user who triggered the transition'
              },
              created_at: { type: :string, format: 'date-time', example: '2024-10-09T14:23:45Z' },
              updated_at: { type: :string, format: 'date-time', example: '2024-10-09T14:23:45Z' }
            },
            required: ['id', 'transitionable_type', 'transitionable_id', 'from_state', 'to_state', 'event', 'user_id']
          },

          # Transition Success Response
          TransitionSuccess: {
            type: :object,
            properties: {
              success: { type: :boolean, example: true },
              article: { '$ref' => '#/components/schemas/Article' }
            },
            required: ['success', 'article']
          },

          # Transition Error Response
          TransitionError: {
            type: :object,
            properties: {
              success: { type: :boolean, example: false },
              errors: { 
                type: :array, 
                items: { type: :string },
                example: ['Transition not allowed from current state']
              }
            },
            required: ['success', 'errors']
          },

          # Reject Action Request
          RejectRequest: {
            type: :object,
            properties: {
              rejection_feedback: {
                type: :string,
                example: 'Please improve the introduction and add more examples.',
                description: 'Detailed feedback explaining why the content is being rejected',
                minLength: 1,
                maxLength: 1000
              }
            },
            required: ['rejection_feedback']
          },

          # Generic Error Response
          Error: {
            type: :object,
            properties: {
              error: { 
                type: :string, 
                example: 'Unauthorized',
                description: 'Error message'
              },
              status: { 
                type: :integer, 
                example: 401,
                description: 'HTTP status code'
              }
            },
            required: ['error']
          }
        }
      }
    }
  }

  config.openapi_format = :json
end
