class User < ApplicationRecord
  has_many :transactions, dependent: :destroy

  devise :database_authenticatable, :registerable, :rememberable
end
