# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { viewer: 0, editor: 1, admin: 2 }

  has_many :articles, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :article2s, dependent: :destroy
  has_many :comment2s, dependent: :destroy
  has_one :custom_template, dependent: :destroy

  after_create :create_custom_template

  def admin?
    role == 'admin'
  end

  def editor?
    role == 'editor'
  end

  def viewer?
    role == 'viewer'
  end

  private

  def create_custom_template
    CustomTemplate.for_user(self)
  end
end
