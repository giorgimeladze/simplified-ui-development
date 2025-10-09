class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { viewer: 0, editor: 1, admin: 2 }

  has_many :articles, dependent: :destroy
  has_many :comments, dependent: :destroy

  def admin?
    role == 'admin'
  end

  def editor?
    role == 'editor'
  end
  
  def viewer?
    role == 'viewer'
  end
end
