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

          # Article2 Schema (Event Sourcing)
          Article2: {
            type: :object,
            properties: {
              id: { type: :string, example: '550e8400-e29b-41d4-a716-446655440000', description: 'UUID identifier' },
              title: { type: :string, example: 'Event-Sourced Article' },
              content: { type: :string, example: 'This article uses event sourcing for state management...' },
              status: { 
                type: :string, 
                enum: ['draft', 'review', 'rejected', 'published', 'privated', 'archived'],
                example: 'published',
                description: 'Current state reconstructed from events'
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
              },
              _embedded: {
                type: :object,
                description: 'HAL-style embedded resources',
                properties: {
                  comment2s: {
                    type: :array,
                    items: { '$ref' => '#/components/schemas/Comment2' }
                  }
                }
              }
            },
            required: ['id', 'title', 'content', 'status', 'links']
          },

          # Comment2 Schema (Event Sourcing)
          Comment2: {
            type: :object,
            properties: {
              id: { type: :string, example: '550e8400-e29b-41d4-a716-446655440001', description: 'UUID identifier' },
              text: { type: :string, example: 'Great event-sourced article! Very informative.' },
              status: { 
                type: :string, 
                enum: ['pending', 'approved', 'rejected', 'deleted'],
                example: 'approved',
                description: 'Current state reconstructed from events'
              },
              article2_id: { type: :string, example: '550e8400-e29b-41d4-a716-446655440000', description: 'UUID of the parent article' },
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

          # Event Schema (Event Sourcing)
          Event: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1, description: 'Event log entry ID' },
              aggregate_id: { type: :string, example: '550e8400-e29b-41d4-a716-446655440000', description: 'UUID of the aggregate' },
              aggregate_type: { 
                type: :string, 
                enum: ['Article2', 'Comment2'],
                example: 'Article2',
                description: 'Type of aggregate that generated the event'
              },
              event_type: { 
                type: :string, 
                example: 'Article2Created',
                description: 'Type of domain event'
              },
              event_data: { 
                type: :object, 
                example: { 'title' => 'New Article', 'content' => 'Article content', 'user_id' => 1 },
                description: 'Event payload data'
              },
              version: { type: :integer, example: 1, description: 'Event version for optimistic concurrency' },
              occurred_at: { type: :string, format: 'date-time', example: '2024-10-09T14:23:45Z', description: 'When the event occurred' },
              correlation_id: { type: :string, example: 'req-123', description: 'Correlation ID for tracing', nullable: true },
              causation_id: { type: :string, example: 'cmd-456', description: 'Causation ID for command tracking', nullable: true },
              metadata: { type: :object, example: { 'user_id' => 1 }, description: 'Additional event metadata', nullable: true },
              created_at: { type: :string, format: 'date-time', example: '2024-10-09T14:23:45Z' },
              updated_at: { type: :string, format: 'date-time', example: '2024-10-09T14:23:45Z' }
            },
            required: ['id', 'aggregate_id', 'aggregate_type', 'event_type', 'event_data', 'version', 'occurred_at']
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
