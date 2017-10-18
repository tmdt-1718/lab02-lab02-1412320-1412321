class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  validates :name, presence: true
  has_many :active_relationships, class_name:  "Relationship",
                                  foreign_key: "user_one_id",
                                  dependent:   :destroy
  has_many :friendship, through: :active_relationships, source: :user_two

  # Add friend with a user.
  def add_friend(other_user)
    friendship << other_user
  end

  # Unfriend with a user.
  def unfriend(other_user)
    friendship.delete(other_user)
  end

  def is_pending?(status)
    status == 1
  end

  # Returns true if the current user is a friend of the other user.
  def is_friend?(status)
    status == 2 || status == 3
  end

  def is_block?(status)
    status == 3
  end
end
